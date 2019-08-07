window.BackApp = (window.BackApp === undefined) ? {} :BackApp

BackApp.Product = class Product {
  constructor(rootElement) {
    this.rootElement = rootElement;
    this.bindUI();
  }

  bindUI() {
    this.rootElement.find('[data-behavior="overwrite-image-toggle"]').on('click', (event) => this.toggleUploadPanel());
  }

  toggleUploadPanel() {
    this.rootElement.find('[data-behavior="upload-section"]').toggleClass('hidden');
  }
}

jQuery(document).on('turbolinks:load', function() {
  const productPage = $('[data-behavior="product-page"]');

  if (productPage.length) {
    new BackApp.Product(productPage);
  }
});

