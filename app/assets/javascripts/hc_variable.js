var HC_JS = {
  widgets:        {},
  routes:         {},
  ecwid:          {},
  shopify:        {},
  static:         {},
  lemonstand:     {},
  last_xhr:       {},
  guest_customer: ((typeof HC_GUEST_CUSTOMER !== 'undefined') ? { name: encodeURIComponent(HC_GUEST_CUSTOMER.name), email: encodeURIComponent(HC_GUEST_CUSTOMER.email)} : null),
  locale:         ((typeof HC_LOCALE !== 'undefined') ? HC_LOCALE : null)
};
