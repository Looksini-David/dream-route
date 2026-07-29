document.addEventListener("DOMContentLoaded", () => {
  const loginForm = document.getElementById("loginForm");
  const emailInput = document.getElementById("email");
  const passwordInput = document.getElementById("password");
  const emailError = document.getElementById("emailError");
  const strengthMsg = document.getElementById("passwordStrength");
  const darkModeToggle = document.getElementById("darkModeToggle");
  const togglePasswordIcon = document.querySelector(".toggle-password");

  // 🌙 Dark mode toggle
  function setDarkMode(enabled) {
    if (enabled) {
      document.body.classList.add("dark-mode");
      darkModeToggle.textContent = "☀️";
    } else {
      document.body.classList.remove("dark-mode");
      darkModeToggle.textContent = "🌙";
    }
    localStorage.setItem("darkModeEnabled", enabled);
  }

  const darkModeSetting = localStorage.getItem("darkModeEnabled") === "true";
  setDarkMode(darkModeSetting);

  darkModeToggle?.addEventListener("click", () => {
    setDarkMode(!document.body.classList.contains("dark-mode"));
  });

  // 👁️ Show/hide password (click to toggle)
  togglePasswordIcon?.addEventListener("click", () => {
    const isHidden = passwordInput.type === "password";
    passwordInput.type = isHidden ? "text" : "password";
    togglePasswordIcon.classList.toggle("fa-eye", !isHidden);
    togglePasswordIcon.classList.toggle("fa-eye-slash", isHidden);
  });

  // 🔐 Password strength
  passwordInput.addEventListener("input", () => {
    const val = passwordInput.value.trim();
    let strength = "";
    let colorClass = "";

    if (val.length === 0) {
      strengthMsg.textContent = "";
      strengthMsg.className = "strength-msg";
      return;
    }

    if (val.length < 6 || /^[a-zA-Z]+$/.test(val)) {
      strength = "Weak";
      colorClass = "strength-weak";
    } else if (val.length >= 6 && /[a-zA-Z]/.test(val) && /\d/.test(val)) {
      strength = "Medium";
      colorClass = "strength-medium";
    } else if (val.length >= 8 && /[!@#$%^&*]/.test(val)) {
      strength = "Strong";
      colorClass = "strength-strong";
    }

    strengthMsg.textContent = `Password Strength: ${strength}`;
    strengthMsg.className = `strength-msg ${colorClass}`;
  });

  // 📧 Email validation
  function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  }

  // ✅ Form submit
  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    let valid = true;

    if (!validateEmail(emailInput.value.trim())) {
      emailError.textContent = "Please enter a valid email address.";
      emailError.style.display = "block";
      emailInput.focus();
      valid = false;
    } else {
      emailError.textContent = "";
      emailError.style.display = "none";
    }

    if (passwordInput.value.trim().length < 6) {
      strengthMsg.textContent = "Password must be at least 6 characters.";
      strengthMsg.className = "strength-msg strength-weak";
      passwordInput.focus();
      valid = false;
    }

    if (!valid) return;

    try {
      const formData = new FormData();
      formData.append("email", emailInput.value.trim());
      formData.append("password", passwordInput.value);

      console.log("Attempting login to: http://127.0.0.1:8001/admin/login");

      const response = await fetch("http://127.0.0.1:8001/admin/login", {
        method: "POST",
        body: formData,
        headers: {
          // Let the browser set Content-Type for FormData
        }
      });

      console.log("Response status:", response.status);

      if (!response.ok) {
        const errorData = await response.json();
        console.error("Login error response:", errorData);
        alert(errorData.detail || "Login failed");
        return;
      }

      const data = await response.json();
      console.log("Login successful:", data);
      localStorage.setItem("access_token", data.access_token);
      localStorage.setItem("adminToken", data.access_token); // Also store as adminToken for compatibility
      window.location.href = "admin_dashboard.html";
    } catch (error) {
      console.error("Login error (detailed):", error);
      console.error("Error name:", error.name);
      console.error("Error message:", error.message);
      
      if (error.name === 'TypeError' && error.message.includes('fetch')) {
        alert("Cannot connect to server. Please ensure the backend is running on http://127.0.0.1:8001");
      } else {
        alert("Server error: " + error.message + ". Please check the console for details.");
      }
    }
  });
});
