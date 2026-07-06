/**
 * Shared Admin Functions
 * Functions used across multiple admin pages
 */

const ADMIN_API_BASE = 'http://127.0.0.1:8000';

// Load and display admin profile picture on any page
async function loadAdminProfilePicture() {
  try {
    // First check localStorage for cached picture
    const savedPicture = localStorage.getItem('adminProfilePicture');
    if (savedPicture) {
      updateProfilePictures(savedPicture);
    }

    // Then fetch fresh data from API
    const response = await fetch(`${ADMIN_API_BASE}/admin/profile`);
    if (response.ok) {
      const data = await response.json();
      
      if (data.profile_picture && data.profile_picture !== savedPicture) {
        localStorage.setItem('adminProfilePicture', data.profile_picture);
        updateProfilePictures(data.profile_picture);
      }
      
      // Update admin name if element exists
      const nameElement = document.getElementById('adminNameDisplay');
      if (nameElement && data.name) {
        nameElement.textContent = data.name;
      }
    }
  } catch (error) {
    console.warn('Failed to load admin profile:', error);
  }
}

// Update all profile picture elements on the page
function updateProfilePictures(imageSrc) {
  const profileElements = document.querySelectorAll('.admin-profile-pic');
  profileElements.forEach(element => {
    element.src = imageSrc;
  });
  
  // Also update common profile picture IDs
  const commonIds = ['adminProfilePic', 'profilePhoto', 'adminAvatar'];
  commonIds.forEach(id => {
    const element = document.getElementById(id);
    if (element) {
      element.src = imageSrc;
    }
  });
}

// Apply saved admin theme
function applyAdminTheme() {
  const savedTheme = localStorage.getItem('adminTheme');
  if (savedTheme === 'dark') {
    document.body.classList.add('dark-mode');
  }
}

// Setup mobile sidebar toggle with enhanced responsiveness
function setupSidebarToggle() {
  const sidebarToggle = document.getElementById('sidebarToggle');
  const sidebar = document.getElementById('sidebar');
  const sidebarOverlay = document.getElementById('sidebarOverlay');
  
  console.log('🔧 Setting up sidebar toggle', { sidebarToggle, sidebar, sidebarOverlay });
  
  if (!sidebarToggle || !sidebar) {
    console.warn('⚠️ Sidebar elements not found', { sidebarToggle, sidebar });
    return;
  }
  
  // Remove any existing event listeners by cloning the button
  const newToggle = sidebarToggle.cloneNode(true);
  sidebarToggle.parentNode.replaceChild(newToggle, sidebarToggle);
  
  // Enhanced mobile sidebar functionality
  newToggle.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    console.log('📱 Sidebar toggle clicked');
    
    const isHidden = sidebar.classList.contains('-translate-x-full');
    
    if (isHidden) {
      // Opening sidebar
      sidebar.classList.remove('-translate-x-full');
      if (sidebarOverlay) {
        sidebarOverlay.classList.remove('hidden');
        sidebarOverlay.classList.remove('opacity-0');
      }
      // Prevent body scroll when sidebar is open on mobile
      if (window.innerWidth < 1024) {
        document.body.classList.add('overflow-hidden');
      }
    } else {
      // Closing sidebar
      closeMobileSidebar();
    }
  });
  
  // Close sidebar when clicking overlay
  if (sidebarOverlay) {
    // Remove existing listeners
    const newOverlay = sidebarOverlay.cloneNode(true);
    sidebarOverlay.parentNode.replaceChild(newOverlay, sidebarOverlay);
    
    newOverlay.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      console.log('🖱️ Overlay clicked - closing sidebar');
      closeMobileSidebar();
    });
  }
  
  // Close sidebar on window resize if moving to desktop
  let resizeTimer;
  window.addEventListener('resize', () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
      if (window.innerWidth >= 1024) {
        closeMobileSidebar();
      }
    }, 100);
  });
  
  // Close sidebar on escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !sidebar.classList.contains('-translate-x-full')) {
      closeMobileSidebar();
    }
  });
  
  console.log('✅ Sidebar toggle setup complete');
}

// Helper function to close mobile sidebar
function closeMobileSidebar() {
  const sidebar = document.getElementById('sidebar');
  const sidebarOverlay = document.getElementById('sidebarOverlay');
  
  console.log('🔒 Closing mobile sidebar', { sidebar, sidebarOverlay });
  
  if (sidebar) {
    sidebar.classList.add('-translate-x-full');
  }
  
  if (sidebarOverlay) {
    sidebarOverlay.classList.add('hidden');
    sidebarOverlay.classList.add('opacity-0');
  }
  
  // Re-enable body scroll
  document.body.classList.remove('overflow-hidden');
}

// Setup profile dropdown functionality
function setupProfileDropdown() {
  const profileDropdown = document.getElementById('profileDropdownToggle');
  const dropdownMenu = document.getElementById('dropdownMenu');
  
  if (profileDropdown && dropdownMenu) {
    console.log('🔧 Setting up profile dropdown');
    
    // Remove any existing event listeners
    profileDropdown.replaceWith(profileDropdown.cloneNode(true));
    const newProfileDropdown = document.getElementById('profileDropdownToggle');
    
    // Add click event listener
    newProfileDropdown.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();
      
      console.log('🔽 Dropdown clicked');
      
      // Toggle dropdown visibility
      dropdownMenu.classList.toggle('hidden');
      
      // Add/remove active state
      newProfileDropdown.classList.toggle('bg-blue-600');
    });
    
    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
      if (!newProfileDropdown.contains(e.target) && !dropdownMenu.contains(e.target)) {
        dropdownMenu.classList.add('hidden');
        newProfileDropdown.classList.remove('bg-blue-600');
      }
    });
    
    // Close dropdown when pressing Escape
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        dropdownMenu.classList.add('hidden');
        newProfileDropdown.classList.remove('bg-blue-600');
      }
    });
    
    console.log('✅ Profile dropdown setup complete');
  } else {
    console.warn('⚠️ Profile dropdown elements not found');
  }
}

// Handle responsive behavior changes
function handleResponsiveChanges() {
  // Make tables horizontally scrollable on mobile
  const tables = document.querySelectorAll('table');
  tables.forEach(table => {
    if (!table.closest('.responsive-table-container')) {
      const wrapper = document.createElement('div');
      wrapper.className = 'responsive-table-container';
      table.parentNode.insertBefore(wrapper, table);
      wrapper.appendChild(table);
    }
  });
  
  // Add mobile-friendly classes to forms
  const forms = document.querySelectorAll('form');
  forms.forEach(form => {
    form.classList.add('responsive-form');
  });
  
  // Add responsive classes to button groups
  const buttonGroups = document.querySelectorAll('.btn-group, .flex.gap-2, .flex.gap-4');
  buttonGroups.forEach(group => {
    if (window.innerWidth < 640) {
      group.classList.add('btn-group-mobile');
    }
  });
  
  // Add touch-friendly classes for mobile devices
  if ('ontouchstart' in window) {
    document.body.classList.add('touch-device');
    
    const interactiveElements = document.querySelectorAll('button, a, [role="button"]');
    interactiveElements.forEach(el => {
      el.classList.add('touch-friendly');
    });
  }
}

// Setup mobile-specific optimizations
function setupMobileOptimizations() {
  // Prevent zoom on input focus (iOS Safari)
  const inputs = document.querySelectorAll('input, select, textarea');
  inputs.forEach(input => {
    input.addEventListener('focus', () => {
      if (window.innerWidth < 768) {
        const viewport = document.querySelector('meta[name="viewport"]');
        if (viewport) {
          viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
        }
      }
    });
    
    input.addEventListener('blur', () => {
      if (window.innerWidth < 768) {
        const viewport = document.querySelector('meta[name="viewport"]');
        if (viewport) {
          viewport.setAttribute('content', 'width=device-width, initial-scale=1.0');
        }
      }
    });
  });
  
  // Add swipe gestures for mobile navigation
  let startX = 0;
  let startY = 0;
  
  document.addEventListener('touchstart', (e) => {
    startX = e.touches[0].clientX;
    startY = e.touches[0].clientY;
  });
  
  document.addEventListener('touchend', (e) => {
    const endX = e.changedTouches[0].clientX;
    const endY = e.changedTouches[0].clientY;
    const diffX = startX - endX;
    const diffY = startY - endY;
    
    // Horizontal swipe detection
    if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 50) {
      if (diffX > 0) {
        // Swipe left - close sidebar
        closeMobileSidebar();
      } else {
        // Swipe right - open sidebar (only if near edge)
        if (startX < 30 && window.innerWidth < 1024) {
          const sidebar = document.getElementById('sidebar');
          const sidebarOverlay = document.getElementById('sidebarOverlay');
          
          if (sidebar && sidebar.classList.contains('-translate-x-full')) {
            sidebar.classList.remove('-translate-x-full');
            if (sidebarOverlay) {
              sidebarOverlay.classList.remove('hidden');
              sidebarOverlay.classList.remove('opacity-0');
            }
            document.body.classList.add('overflow-hidden');
          }
        }
      }
    }
  });
}

// Initialize admin common features
function initializeAdminCommon() {
  console.log('🚀 Initializing admin common features');
  
  // Setup sidebar toggle FIRST - this is critical for mobile
  setupSidebarToggle();
  
  // Load profile picture
  loadAdminProfilePicture();
  
  // Apply theme
  applyAdminTheme();
  
  // Set up profile dropdown
  setupProfileDropdown();
  
  // Handle responsive changes
  handleResponsiveChanges();
  
  // Setup mobile optimizations
  setupMobileOptimizations();
  
  // Re-run responsive checks on window resize
  let resizeTimeout;
  window.addEventListener('resize', () => {
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(() => {
      handleResponsiveChanges();
    }, 150);
  });
  
  console.log('✅ Admin common initialization complete');
}

// Call initialization when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeAdminCommon);
} else {
  // DOM already loaded, run immediately
  initializeAdminCommon();
}

console.log('🔧 Admin common functions loaded');