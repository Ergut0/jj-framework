import { useEffect, useState } from 'react';
import { createHashRouter, RouterProvider } from 'react-router';
import { fetchNui, isBrowser, useNuiEvent } from './lib/nui';
import { Characters } from './pages/Characters';
import { Loading } from './pages/Loading';
import { Selector } from './pages/Selector';

const router = createHashRouter([
  { path: '/', element: <Loading /> },
  { path: '/characters', element: <Characters /> },
  { path: '/selector', element: <Selector /> },
]);

export function App() {
  const [visible, setVisible] = useState(isBrowser());

  useEffect(() => {
    if (isBrowser()) return;
    fetchNui<{ active: boolean }>('nuiReady').then((result) => {
      if (result?.active) {
        setVisible(true);
        router.navigate('/');
      }
    });
  }, []);

  useNuiEvent('hideInterface', () => setVisible(false));

  useNuiEvent('showInterface', () => {
    setVisible(true);
    router.navigate('/');
  });

  useNuiEvent('showZonesSelector', () => {
    setVisible(true);
    router.navigate('/selector');
  });

  return <>{visible && <RouterProvider router={router} />}</>;
}
