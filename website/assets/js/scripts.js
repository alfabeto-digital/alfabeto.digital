// Inject HTML into containers
function loadHTML(containerId, filePath, callback) {
  return fetch(filePath)
    .then(response => response.text())
    .then(data => {
      const container = document.getElementById(containerId);
      container.innerHTML = data;
      if (callback) callback();
      if (containerId === 'dynamic-content') {
        sessionStorage.setItem('currentPage', filePath);
      }
    })
    .catch(error => console.error(`Error loading ${filePath}:`, error));
}

// Update HTML
function updateContent(page) {
  loadHTML('dynamic-content', page, () => {
    const icons = document.querySelectorAll('.navbar .icon-box');
    icons.forEach(icon => {
      icon.classList.remove('selected');
      if (icon.dataset.page === page) icon.classList.add('selected');
    });
  });
}

// Render menu
function initMenu() {
  const menu = document.querySelector('#expanded-menu-container .expanded-menu');
  const button = document.querySelector('.menu-button');

  if (!menu || !button) return;

  button.onclick = (e) => {
    e.stopPropagation();
    menu.classList.toggle('active');
    document.getElementById('floating-menu').style.display = 'none';
  };

  document.onclick = () => {
    menu.classList.remove('active');
    document.getElementById('floating-menu').style.display = 'flex';
  };
  
  menu.onclick = (e) => {
    const icon = e.target.closest('.icon-box');
    if (icon) {
      updateContent(icon.dataset.page);
      menu.classList.remove('active');
      document.getElementById('floating-menu').style.display = 'flex';
    }
  };

  const savedPage = sessionStorage.getItem('currentPage');
  if (savedPage) updateContent(savedPage);
}

// Events listener
document.addEventListener('DOMContentLoaded', () => {
  sessionStorage.removeItem('currentPage');
  
  Promise.all([
    loadHTML('header-container', '../components/header.html'),
    loadHTML('expanded-menu-container', '../components/menu.html')
  ]).then(() => {
    initMenu();
    
    document.getElementById('header-click-area').onclick = () => {
      sessionStorage.setItem('currentPage', '../components/landing.html');
      updateContent('../components/landing.html');
    };

    updateContent('../components/landing.html');
  });
});