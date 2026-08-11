window.addEventListener("load", function() {
    const dialog = document.getElementById("delete-confirm-dialog");

    if (!dialog) {
        return;
    }

    let pendingForm = null;

    document.querySelectorAll("button.delete").forEach(button => {
        button.addEventListener("click", (e) => {
            e.preventDefault();
            pendingForm = button.closest("form");
            dialog.showModal();
        });
    });

    dialog.querySelector("button.cancel").addEventListener("click", () => {
        pendingForm = null;
        dialog.close();
    });

    dialog.querySelector("button.confirm").addEventListener("click", () => {
        const form = pendingForm;
        pendingForm = null;
        dialog.close();

        if (form) {
            form.submit();
        }
    });
})
