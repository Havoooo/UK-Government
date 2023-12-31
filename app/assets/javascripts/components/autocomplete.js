//= require accessible-autocomplete/dist/accessible-autocomplete.min.js
window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function Autocomplete ($module) {
    this.$module = $module
  }

  Autocomplete.prototype.init = function () {
    var $select = this.$module.querySelector('select')

    var defaultOptions = {
      selectElement: $select,
      minLength: 3,
      showAllValues: $select.multiple,
      showNoOptionsFound: true,
      onConfirm: function (query) {
        var category = $select.getAttribute('data-track-category')
        var label = $select.getAttribute('data-track-label')
        var action = query
        if (category && label) {
          window.GOVUK.analytics.trackEvent(category, action, { label: label })
        }

        var matchingOption
        if (query) {
          matchingOption = [].filter.call($select.options, function (option) {
            return (option.textContent || option.innerText) === query
          })[0]
        } else {
          matchingOption = [].filter.call($select.options, function (option) {
            return option.value === ''
          })[0]
        }
        if (matchingOption) { matchingOption.selected = true }
      }
    }

    var assignedOptions = JSON.parse(this.$module.dataset.autocompleteConfigurationOptions)

    var configurationOptions = Object.assign(defaultOptions, assignedOptions)

    // disabled eslint because we can not control the name of the constructor (expected to be EnhanceSelectElement)
    new window.accessibleAutocomplete.enhanceSelectElement(configurationOptions) // eslint-disable-line no-new, new-cap
  }

  Modules.Autocomplete = Autocomplete
})(window.GOVUK.Modules)
