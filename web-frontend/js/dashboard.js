document.addEventListener("DOMContentLoaded", function () {
  const profileToggle = document.getElementById("profileDropdownToggle");
  const dropdownMenu = document.getElementById("dropdownMenu");
  const sidebarToggle = document.getElementById("sidebarToggle");
  const sidebar = document.getElementById("sidebar");

  // Profile dropdown toggle
  profileToggle?.addEventListener("click", () => {
    dropdownMenu.classList.toggle("hidden");
  });

  // Close dropdown on outside click
  document.addEventListener("click", (e) => {
    if (!profileToggle.contains(e.target) && !dropdownMenu.contains(e.target)) {
      dropdownMenu.classList.add("hidden");
    }
  });

  // Sidebar toggle for mobile
  sidebarToggle?.addEventListener("click", () => {
    sidebar.classList.toggle("-translate-x-full");
  });

  // Quiz Score Chart
  const quizCanvas = document.getElementById("quizScoreChart");
  if (quizCanvas) {
    const ctxQuiz = quizCanvas.getContext("2d");
    new Chart(ctxQuiz, {
      type: "pie",
      data: {
        labels: ["Excellent", "Good", "Average", "Poor"],
        datasets: [
          {
            data: [12, 19, 7, 2],
            backgroundColor: ["#0B2545", "#3CC6E0", "#2D95C4", "#225C9A"],
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: "top",
            labels: { font: { size: 12 } },
          },
        },
      },
    });
  }

  // Users by Role Chart
  const userCanvas = document.getElementById("userRoleChart");
  if (userCanvas) {
    const ctxUsers = userCanvas.getContext("2d");
    new Chart(ctxUsers, {
      type: "doughnut",
      data: {
        labels: ["Students", "Freshers", "Job"],
        datasets: [
          {
            data: [5, 10, 20],
            backgroundColor: ["#0B2545", "#225C9A", "#2D95C4"],
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: "top",
            labels: { font: { size: 12 } },
          },
        },
      },
    });
  }
});
