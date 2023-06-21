window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function GovspeakEditor (module) {
    this.module = module
  }

  GovspeakEditor.prototype.init = function () {
    this.initPreview()
  }

  GovspeakEditor.prototype.getCsrfToken = function () {
    return document.querySelector('meta[name="csrf-token"]').content
  }

  GovspeakEditor.prototype.getRenderedGovspeak = function (body, callback) {
    var data = this.generateFormData(body)

    var request = new XMLHttpRequest()
    request.open('POST', '/government/admin/preview', false)
    request.setRequestHeader('X-CSRF-Token', this.getCsrfToken())
    request.onreadystatechange = callback
    request.send(data)
  }

  GovspeakEditor.prototype.generateFormData = function (body) {
    var data = new FormData()
    data.append('body', body)
    data.append('authenticity_token', this.getCsrfToken())
    if (this.alternativeFormatProviderId()) {
      data.append('alternative_format_provider_id', this.alternativeFormatProviderId())
    }

    var imageIds = this.getImageIds()
    for (var index = 0; index < imageIds.length; index++) {
      data.append('image_ids[]', imageIds[index])
    }

    var attachmentIds = this.getAttachmentIds()
    for (var i = 0; i < attachmentIds.length; i++) {
      data.append('attachment_ids[]', attachmentIds[i])
    }

    return data
  }

  GovspeakEditor.prototype.initPreview = function () {
    var previewToggle = this.module.querySelector('.js-app-c-govspeak-editor__preview-button')
    var trackToggle = previewToggle.getAttribute('data-preview-toggle-tracking') === 'true'
    var preview = this.module.querySelector('.app-c-govspeak-editor__preview')
    var error = this.module.querySelector('.app-c-govspeak-editor__error')
    var textareaWrapper = this.module.querySelector('.app-c-govspeak-editor__textarea')
    var textarea = this.module.querySelector(previewToggle.getAttribute('data-content-target'))

    previewToggle.addEventListener('click', function (e) {
      e.preventDefault()

      var previewMode = previewToggle.innerText === 'Preview'

      previewToggle.innerText = previewMode ? 'Back to edit' : 'Preview'
      textareaWrapper.classList.toggle('app-c-govspeak-editor__textarea--hidden')

      if (previewMode) {
        preview.classList.add('app-c-govspeak-editor__preview--show')
        this.getRenderedGovspeak(textarea.value, function (event) {
          var response = event.currentTarget

          if (response.readyState === 4) {
            if (response.status === 200) {
              preview.innerHTML = response.responseText
            }

            if (response.status === 403) {
              error.classList.add('app-c-govspeak-editor__error--show')
              preview.classList.remove('app-c-govspeak-editor__preview--show')
            }
          }
        })
      } else {
        preview.classList.remove('app-c-govspeak-editor__preview--show')
        error.classList.remove('app-c-govspeak-editor__error--show')
      }

      if (trackToggle) {
        GOVUK.analytics.trackEvent(
          previewToggle.getAttribute('data-preview-toggle-track-category'),
          previewToggle.getAttribute('data-preview-toggle-track-action'),
          { label: previewMode ? 'preview' : 'edit' }
        )
      }
    }.bind(this))
  }

  GovspeakEditor.prototype.getImageIds = function () {
    var imagesIds = this.module.getAttribute('data-image-ids')
    imagesIds = imagesIds ? JSON.parse(imagesIds) : []

    return imagesIds.filter(function (id) { return id })
  }

  GovspeakEditor.prototype.getAttachmentIds = function () {
    var attachmentIds = this.module.getAttribute('data-attachment-ids')
    attachmentIds = attachmentIds ? JSON.parse(attachmentIds) : []

    return attachmentIds.filter(function (id) { return id })
  }

  GovspeakEditor.prototype.alternativeFormatProviderId = function () {
    return this.module.getAttribute('data-alternative-format-provider-id')
  }

  Modules.GovspeakEditor = GovspeakEditor
})(window.GOVUK.Modules)
