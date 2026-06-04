(function () {
  var root = document.documentElement;
  var KEY = 'orca-lang';

  function set(l) {
    root.setAttribute('data-lang', l);
    root.setAttribute('lang', l);
    try { localStorage.setItem(KEY, l); } catch (e) {}
  }

  var saved;
  try { saved = localStorage.getItem(KEY); } catch (e) {}
  if (!saved) {
    saved = (navigator.language || 'ru').toLowerCase().indexOf('ru') === 0 ? 'ru' : 'en';
  }
  set(saved);

  document.querySelectorAll('.lang button').forEach(function (b) {
    b.addEventListener('click', function () { set(b.getAttribute('data-set')); });
  });

  var els = document.querySelectorAll('.reveal');
  if (!('IntersectionObserver' in window) || matchMedia('(prefers-reduced-motion: reduce)').matches) {
    els.forEach(function (e) { e.classList.add('in'); });
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
    });
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
  els.forEach(function (e) { io.observe(e); });
})();
