// Tipos equivalentes a las clases de datos de Kotlin

export interface Hotel {
  id: string;
  name: string;
  description: string;
  location: string;
  imageUrl: string;
  photos: string[];
  rating: number;
  priceRange: string;
}

export interface User {
  name: string;
  email: string;
  phone: string;
}

export interface SearchHistory {
  id: string;
  hotelName: string;
  searchDate: string;
  location: string;
}

export interface Quote {
  hotelId: string;
  hotelName: string;
  checkInDate: string;
  checkOutDate: string;
  adults: number;
  children: number;
  childrenAges: number[];
  nights: number;
}

export interface TabItem {
  title: string;
  icon: any; // ComponentType de React
  path: string;
} 