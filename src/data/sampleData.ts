import { Hotel, User, SearchHistory } from '../types';

export const sampleHotels: Hotel[] = [
  {
    id: "1",
    name: "Hotel Terma de Puyehue",
    description: "Hotel de lujo en el corazón de las termas de Puyehue con vistas espectaculares a los volcanes. Disfruta de aguas termales y servicio personalizado.",
    location: "Puyehue, Chile",
    imageUrl: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=600&fit=crop",
    photos: [
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=600&fit=crop",
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&h=600&fit=crop",
      "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&h=600&fit=crop",
      "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&h=600&fit=crop"
    ],
    rating: 4.8,
    priceRange: "€300-€600"
  },
  {
    id: "2",
    name: "Hotel Huilo-Huilo",
    description: "Resort de montaña con acceso directo al bosque nativo y piscina natural. Perfecto para unas vacaciones en la Patagonia.",
    location: "Panguipulli, Chile",
    imageUrl: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400",
    photos: [
      "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400",
      "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=400",
      "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400"
    ],
    rating: 4.6,
    priceRange: "€200-€450"
  },
  {
    id: "3",
    name: "Hotel Corralco Resort",
    description: "Hotel boutique con encanto de montaña en el corazón de la reserva natural, cerca de las pistas de esquí. Arquitectura tradicional con comodidades modernas.",
    location: "Lonquimay, Chile",
    imageUrl: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400",
    photos: [
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400",
      "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400",
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400"
    ],
    rating: 4.7,
    priceRange: "€120-€250"
  },
  {
    id: "4",
    name: "Hotel Futangue",
    description: "Hotel moderno ideal para viajes de aventura con salas de conferencias y centro de fitness. Ubicado en el corazón de la naturaleza.",
    location: "Lago Ranco, Chile",
    imageUrl: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400",
    photos: [
      "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400",
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400",
      "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400"
    ],
    rating: 4.5,
    priceRange: "€180-€320"
  },
  {
    id: "5",
    name: "Termas de Aguas Calientes",
    description: "Históricas termas ubicadas en un edificio del siglo XIX. Experiencia única combinando historia y aguas termales.",
    location: "San José de Maipo, Chile",
    imageUrl: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400",
    photos: [
      "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400",
      "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400",
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400"
    ],
    rating: 4.9,
    priceRange: "€250-€500"
  }
];

export const sampleUser: User = {
  name: "Juan Pérez",
  email: "juan.perez@email.com",
  phone: "+34 612 345 678"
};

export const sampleSearchHistory: SearchHistory[] = [
  {
    id: "1",
    hotelName: "Hotel Terma de Puyehue",
    searchDate: "2024-01-15",
    location: "Puyehue"
  },
  {
    id: "2",
    hotelName: "Hotel Huilo-Huilo",
    searchDate: "2024-01-10",
    location: "Panguipulli"
  },
  {
    id: "3",
    hotelName: "Hotel Corralco Resort",
    searchDate: "2024-01-05",
    location: "Lonquimay"
  }
]; 