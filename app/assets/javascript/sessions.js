function showLoader() {
    document.querySelector("div.providers").classList.add("hide");
    document.querySelector("div.loader").classList.remove("hide");
}

window.addEventListener("load", function() {
    const providerForms = document.querySelectorAll("form.provider");

    providerForms.forEach(providerForm => {
        providerForm.onsubmit = (e) => showLoader();
    })

    if (providerForms.length === 1) {
        providerForms[0].submit();
    }
})
