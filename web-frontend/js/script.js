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

  // 👁️ Show/hide password
  togglePasswordIcon?.addEventListener("mouseenter", () => (passwordInput.type = "text"));
  togglePasswordIcon?.addEventListener("mouseleave", () => (passwordInput.type = "password"));
  togglePasswordIcon?.addEventListener("focus", () => (passwordInput.type = "text"));
  togglePasswordIcon?.addEventListener("blur", () => (passwordInput.type = "password"));

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

      console.log("Attempting login to: http://127.0.0.1:8000/admin/login");

      const response = await fetch("http://127.0.0.1:8000/admin/login", {
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
        alert("Cannot connect to server. Please ensure the backend is running on http://127.0.0.1:8000");
      } else {
        alert("Server error: " + error.message + ". Please check the console for details.");
      }
    }
  });

  // 🔗 Google Login Button
  const googleBtn = document.querySelector('.google-btn');
  googleBtn?.addEventListener('click', async () => {
    try {
      // Show loading state
      googleBtn.disabled = true;
      googleBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Connecting to Google...';
      
      // Simulate Google OAuth flow (in production, use Google's OAuth library)
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate network delay
      
      // For demo purposes, use a simulated token
      const googleToken = "admin-google-token-simulation";
      
      const response = await fetch("http://127.0.0.1:8000/admin/google-login", {
        method: "POST",
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: `google_token=${encodeURIComponent(googleToken)}`
      });

      if (!response.ok) {
        const errorData = await response.json();
        alert(errorData.detail || "Google login failed");
        return;
      }

      const data = await response.json();
      
      // Store token and admin info
      localStorage.setItem("access_token", data.access_token);
      localStorage.setItem("adminInfo", JSON.stringify(data.admin));
      
      // Show success message
      googleBtn.innerHTML = '<i class="fas fa-check"></i> Success! Redirecting...';
      googleBtn.style.backgroundColor = '#4CAF50';
      
      // Redirect to dashboard
      setTimeout(() => {
        window.location.href = "admin_dashboard.html";
      }, 1500);
      
    } catch (error) {
      console.error("Google login error:", error);
      alert("Google login failed. Please try again.");
    } finally {
      // Reset button state if there was an error
      if (googleBtn.innerHTML.includes('Connecting') || googleBtn.innerHTML.includes('Success')) {
        setTimeout(() => {
          googleBtn.disabled = false;
          googleBtn.innerHTML = `
            <img src="https://developers.google.com/identity/images/g-logo.png" alt="Google logo" width="20" height="20" />
            Login with Google
          `;
          googleBtn.style.backgroundColor = '';
        }, 2000);
      }
    }
  });
});
