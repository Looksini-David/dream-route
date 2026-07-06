// document.addEventListener("DOMContentLoaded", function () {
//   const form = document.getElementById("loginForm");

//   form.addEventListener("submit", async (event) => {
//     event.preventDefault();

//     const email = document.getElementById("email").value;
//     const password = document.getElementById("password").value;

//     const formData = new FormData();
//     formData.append("email", email);
//     formData.append("password", password);

//     const res = await fetch("http://127.0.0.1:8000/admin/login", {
//       method: "POST",
//       body: formData, // no need to set content-type; browser sets it automatically
//     });

//     const data = await res.json();
//     console.log(data);

//     if (res.ok) {
//       alert("✅ Login successful!");
//       localStorage.setItem("adminToken", data.access_token);
//       window.location.href = "admin_dashboard.html";
//     } else {
//       alert("❌ " + (data.detail || "Login failed"));
//     }
//   });
// });


// new code for login.js
document.addEventListener("DOMContentLoaded", function () {
  const form = document.getElementById("loginForm");
  const emailInput = document.getElementById("email");
  const passwordInput = document.getElementById("password");
  const emailError = document.getElementById("emailError");
  const passwordStrength = document.getElementById("passwordStrength");
  const submitBtn = form.querySelector('button[type="submit"]');

  // ---------- Dark Mode Toggle ----------
  const darkModeToggle = document.getElementById("darkModeToggle");
  if (darkModeToggle) {
    darkModeToggle.addEventListener("click", () => {
      document.body.classList.toggle("dark-mode");
      darkModeToggle.textContent = document.body.classList.contains("dark-mode") ? "☀️" : "🌙";
    });
  }

  // ---------- Show/Hide Password ----------
  const togglePasswordIcon = document.querySelector(".toggle-password");
  if (togglePasswordIcon) {
    togglePasswordIcon.addEventListener("click", () => {
      const isPassword = passwordInput.type === "password";
      passwordInput.type = isPassword ? "text" : "password";
      togglePasswordIcon.classList.toggle("fa-eye");
      togglePasswordIcon.classList.toggle("fa-eye-slash");
    });
  }

  // ---------- Validation Helpers ----------
  function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  function setFieldError(el, message) {
    el.textContent = message;
    el.style.color = message ? "#dc3545" : "";
  }

  function validateEmailField() {
    const value = emailInput.value.trim();

    if (!value) {
      setFieldError(emailError, "Email is required.");
      return false;
    }
    if (!isValidEmail(value)) {
      setFieldError(emailError, "Enter a valid email address.");
      return false;
    }
    setFieldError(emailError, "");
    return true;
  }

  function validatePasswordField() {
    const value = passwordInput.value;

    if (!value) {
      setFieldError(passwordStrength, "Password is required.");
      return false;
    }
    if (value.length < 6) {
      setFieldError(passwordStrength, "Password must be at least 6 characters.");
      return false;
    }
    setFieldError(passwordStrength, "");
    return true;
  }

  // ---------- Real-time validation ----------
  emailInput.addEventListener("blur", validateEmailField);
  emailInput.addEventListener("input", () => {
    if (emailError.textContent) validateEmailField();
  });

  passwordInput.addEventListener("blur", validatePasswordField);
  passwordInput.addEventListener("input", () => {
    if (passwordStrength.textContent) validatePasswordField();
  });

  // ---------- Message banner (no more alert()) ----------
  function showMessage(text, type) {
    let message = document.getElementById("message");
    if (!message) {
      message = document.createElement("div");
      message.id = "message";
      message.setAttribute("aria-live", "polite");
      form.parentNode.insertBefore(message, form.nextSibling);
    }
    message.textContent = text;
    message.className = `mt-3 alert ${type === "error" ? "alert-danger" : "alert-success"}`;
    message.style.display = "block";
  }

  // ---------- Form Submit ----------
  form.addEventListener("submit", async (event) => {
    event.preventDefault();

    const emailValid = validateEmailField();
    const passwordValid = validatePasswordField();

    if (!emailValid || !passwordValid) {
      return; // stop here, inline errors already shown
    }

    const email = emailInput.value.trim();
    const password = passwordInput.value;

    const formData = new FormData();
    formData.append("email", email);
    formData.append("password", password);

    submitBtn.disabled = true;
    const originalText = submitBtn.textContent;
    submitBtn.textContent = "Logging in...";

    try {
      const res = await fetch("http://127.0.0.1:8000/admin/login", {
        method: "POST",
        body: formData, // browser sets content-type automatically for FormData
      });

      const data = await res.json();

      if (res.ok) {
        showMessage("✅ Login successful! Redirecting...", "success");
        localStorage.setItem("adminToken", data.access_token);
        setTimeout(() => {
          window.location.href = "admin_dashboard.html";
        }, 1000);
      } else {
        // FastAPI 422 validation errors come as a list under detail
        if (Array.isArray(data.detail)) {
          showMessage(`❗ ${data.detail[0].msg}`, "error");
        } else {
          showMessage(`❗ ${data.detail || "Login failed"}`, "error");
        }
      }
    } catch (error) {
      console.error("Login error:", error);
      showMessage("❗ Network error. Please check your connection.", "error");
    } finally {
      submitBtn.disabled = false;
      submitBtn.textContent = originalText;
    }
  });
});