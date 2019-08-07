window.BackApp = (window.BackApp === undefined) ? {} : BackApp;
BackApp.Billing = class Billing {

  constructor(rootElement) {
    this.rootElement = rootElement;
    this.initState();

    this.initChargebee();

    this.bindUI();
  }

  bindUI() {
    this.rootElement.find('.js-show-chargebee')
      .on('click', () => this.initChargebeeSubscription());

    this.rootElement.find('[data-behavior="subscribe"]')
      .on('click', (event) => this.subscribe(event.target));

    this.rootElement.find('[data-behavior="unsubscribe"]')
      .on('click', () => this.unsubscribe());

    this.rootElement.find('[data-behavior="manage-subscription"]')
      .on('click', () => this.showChargebeeSelfServePortal(event.target));

    this.addonCheckboxes().on('change', (event) => this.changeAddonState(event.target));

    this.selectPlanButtons().on('click', (event) => this.changePlan(event.target));
  }


  initChargebee() {
    const chargebeeSite = this.rootElement.data('chargebee-site');

    Chargebee.init({
      site: chargebeeSite
    });
    this.chargebeeInstance = Chargebee.getInstance();
  }

  bundleContainer() {
    return this.rootElement.find('[data-purpose="bundle-summary-container"]');
  }

  subscriptionContainer() {
    return this.rootElement.find('[data-purpose="subscription-section"]');
  }

  plans() {
    return this.rootElement.find('[data-behavior="plan"]');
  }

  selectPlanButtons() {
    return this.rootElement.find('[data-behavior="select-plan"]');
  }

  addonCheckboxes() {
    return this.rootElement.find('[data-behavior="addon-toggle"]');
  }

  initState() {
    this.selectedPlan = this.plans().find('[data-status="active"]').first().data('planId');
    this.initAddonsState();
  }

  initAddonsState() {
    const checkedAddons = this.addonCheckboxes().filter(':checked').toArray();

    const addonIds = checkedAddons.map(addon => $(addon).data('addonId'));
    this.selectedAddons = new Set(addonIds);
  }

  subscribe(element) {
    this.selectedPlan = $(element).parents('[data-behavior="plan"]').data('planId');
    const bundleId = this.rootElement.find('[data-purpose="bundle-info"]').data('bundleId');
    const bundleData = { plan: this.selectedPlan,
                       addons: [...this.selectedAddons] };

    const url = HC_JS.routes.back_subscriptions_path();
    const xhr = $.ajax({
      url: url,
      data: { bundle_id: bundleId, bundle: bundleData },
      method: 'POST'
    });

    xhr.then(result => {
      if (result.platform == 'chargebee') {
        const showHostedPage = result.action == 'create';
        if (showHostedPage) {
          this.initChargebeeSubscription(result.hosted_page, result.subscription);
        }
        else {
          window.location.reload();
        }
      }
      else {
        window.location.href = result.redirect_url;
      }
    });
  }

  retrySubscription() {
    const subscriptionId = this.subscriptionContainer().data('subscriptionId');
    const url = HC_JS.routes.new_back_shopify_payment_path({subscription_id: subscriptionId});
    window.location.href = url;
  }

  changePlan(element) {
    this.refreshSummary();
  }

  changeAddonState(addonToggle) {
    const addonId = $(addonToggle).data('addonId');
    if (addonToggle.checked) {
      this.selectedAddons.add(addonId);
    } else {
      this.selectedAddons.delete(addonId);
    }
    this.refreshSummary();
  }

  showChargebeeSelfServePortal(manageSubscriptionLink) {
    const subscriptionId = $(manageSubscriptionLink).data('subscriptionId');
    const portalSessionXhr = this.initPortalSession(subscriptionId);
    portalSessionXhr.then(result => {
      const promise = this.wrapInPromise(result.portal_session);
      this.chargebeeInstance.setPortalSession(() => {
        return promise;
      });
      const cbPortal = this.chargebeeInstance.createChargebeePortal();
      cbPortal.open({
        close() {}
      });
    });
  }

  initPortalSession(subscriptionId) {
    const url = HC_JS.routes.portal_back_chargebee_payments_path();
    const data = { "subscription_id": subscriptionId };
    return $.ajax({
      url: url,
      data: data,
      method: 'POST'
    });
  }

  initChargebeeSubscription(hostedPage, subscription) {
    const promise = this.wrapInPromise(hostedPage);
    const self = this;
    window.scrollTo(0,0); // scroll to the top before chargebee popup
    this.chargebeeInstance.openCheckout({
      hostedPage: function() {
        return promise;
      },
      close: function() {
        self.submitHostedPage(hostedPage.id);
      },
      success: function(hostedPageId) {
        self.submitHostedPage(hostedPageId);
      }
    });
  }

  submitHostedPage(hostedPageId) {
    const url = HC_JS.routes.confirm_back_chargebee_payments_path();
    const data = { hosted_page_id: hostedPageId };

    $.ajax({
      url: url,
      data: data,
      method: 'POST'
    }).then((result) => {
      if (result.status == 'cancelled') {
        window.location.reload();
      } else {
        setTimeout( () => {
          window.location.reload();
        }, 3000);
      }
     }).fail((failure) => {
      console.log("Error during payment");
      // page would be reloaded with flash message
    });
  }

  // we need this since jQuery 1.x doesn't implement proper Promise/A+ spec and
  // doesn't have .catch method on promise instance. Chargebee however expects
  // promise that support both .then and .catch
  wrapInPromise(value) {
    return new Promise(function(resolve, reject) {
      resolve(value);
    });
  }

  render() {
  }
};


jQuery(document).on('turbolinks:load', function() {
  const container = $('[data-behavior=back-billing-container]');

  if (container.length) {
    const billing = new BackApp.Billing(container);
    billing.render();
  }
});
