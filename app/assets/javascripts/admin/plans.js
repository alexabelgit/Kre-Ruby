window.AdminApp = (window.AdminApp === undefined) ? {} : AdminApp;
AdminApp.Plans = class Plans {

  constructor(rootElement) {
    this.rootElement = rootElement;
    this.bindUI();
    this.init()
  }

  bindUI() {
    this.rootElement.find('[data-behavior="select-all"]')
      .on('click', () => this.toggleAllPlans(event.target));

    this.rootElement.find('[data-behavior="export-as-csv"]').on('click', () => this.exportAsCsv());
    this.platformSelect().on('change', () => this.changePlatform(event.target));
    this.pricingModelSelect().on('change', () => this.changePricingModel(event.target));
  }

  init() {
    this.changePlatform(this.platformSelect());
    this.changePricingModel(this.pricingModelSelect());
  }

  changePlatform(platformSelect) {
    const newPlatform = jQuery(platformSelect).find(':selected').text();

    this.rootElement.find('[data-platform="shopify"]').toggleClass('hidden', newPlatform !== "shopify");
    this.rootElement.find('[data-platform="!shopify"]').toggleClass('hidden', newPlatform === "shopify");
  }

  changePricingModel(pricingModelSelect) {
    const newPricingModel = jQuery(pricingModelSelect).find(':selected').text();

    this.rootElement.find('[data-pricing="orders"]').toggleClass('hidden', newPricingModel === 'products' );
    this.rootElement.find('[data-pricing="products"]').toggleClass('hidden', newPricingModel === 'orders' );
  }

  toggleAllPlans(mainCheckbox) {
    this.planCheckboxes().prop("checked", jQuery(mainCheckbox).prop("checked"));
  }

  exportAsCsv() {
    const ids = $.map(this.planCheckboxes().filter(':checked'), el => el.value);
    let url = '/admin/pricing/plans.csv?' + $.param({ plan_ids: ids} );
    window.open(url);
  }

  // selectors

  platformSelect() {
    return this.rootElement.find('[data-behavior="platform-select"]');
  }

  pricingModelSelect() {
    return this.rootElement.find('[data-behavior="pricing-model-select"]')
  }

  planCheckboxes() {
    return this.rootElement.find('[data-behavior="plan-checkbox"]');
  }
}

jQuery(document).on('turbolinks:load', function() {
  const container = jQuery('[data-behavior="admin-container"]');

  if (container.length) {
    new AdminApp.Plans(container);
  }
});
