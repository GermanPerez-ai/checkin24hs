import { Routes, Route } from 'react-router-dom';
import { FlorProvider } from './context/FlorContext';
import { Home } from './pages/Home';
import { HotelDetail } from './pages/HotelDetail';
import { NovedadDetail } from './pages/NovedadDetail';
import { DestinoPais } from './pages/DestinoPais';
import { Packs } from './pages/Packs';
import { PackDetail } from './pages/PackDetail';
import { Promos } from './pages/Promos';
import { PromoDetail } from './pages/PromoDetail';
import { TrackPageview } from './components/TrackPageview';
import './index.css';

function App() {
  return (
    <FlorProvider>
      <TrackPageview />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/chile" element={<DestinoPais />} />
        <Route path="/argentina" element={<DestinoPais />} />
        <Route path="/internacionales" element={<DestinoPais />} />
        <Route path="/packs" element={<Packs />} />
        <Route path="/pack/:slug" element={<PackDetail />} />
        <Route path="/promos" element={<Promos />} />
        <Route path="/promo/:slug" element={<PromoDetail />} />
        <Route path="/hotel/:slug" element={<HotelDetail />} />
        <Route path="/novedad/:slugOrId" element={<NovedadDetail />} />
      </Routes>
    </FlorProvider>
  );
}

export default App;
