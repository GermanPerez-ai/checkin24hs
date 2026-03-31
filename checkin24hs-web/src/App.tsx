import { Routes, Route } from 'react-router-dom';
import { FlorProvider } from './context/FlorContext';
import { Home } from './pages/Home';
import { HotelDetail } from './pages/HotelDetail';
import { NovedadDetail } from './pages/NovedadDetail';
import './index.css';

function App() {
  return (
    <FlorProvider>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/hotel/:slug" element={<HotelDetail />} />
        <Route path="/novedad/:slugOrId" element={<NovedadDetail />} />
      </Routes>
      {/* Botón WhatsApp en index.html */}
    </FlorProvider>
  );
}

export default App;
