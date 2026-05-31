// lutroll-data.jsx — sample rolls, photos, and LUT filter recipes

/* CSS filter() recipes per LUT — these visibly transform a real photo
   in the browser, so before/after demos actually work. */
const LR_FILTERS = {
  warm_picnic:   "sepia(0.30) saturate(1.18) hue-rotate(-8deg) contrast(0.96) brightness(1.04)",
  tokyo_night:   "saturate(1.25) hue-rotate(195deg) contrast(1.12) brightness(0.85)",
  soft_green:    "sepia(0.20) saturate(0.82) hue-rotate(40deg) brightness(1.02)",
  creamy_street: "sepia(0.42) saturate(0.78) contrast(0.94) brightness(1.05)",
  sunny_film:    "saturate(1.22) brightness(1.06) contrast(1.06) hue-rotate(-6deg)",
  cozy_room:     "sepia(0.46) saturate(0.92) contrast(0.92) brightness(0.97) hue-rotate(-4deg)",
  paris_blue:    "saturate(0.95) hue-rotate(-14deg) contrast(1.05) brightness(0.97)",
};

/* Photo "stock" — we use picsum.photos with deterministic seeds.
   Each seed reliably returns the same picture, so the prototype is stable. */
const photo = (seed, w = 800, h = 800) =>
  `https://picsum.photos/seed/${seed}/${w}/${h}`;

const LR_ROLLS = [
  {
    id: "warm_picnic",
    name: "Warm Picnic",
    createdAt: "May 8",
    sample: photo("picnic-basket-grass", 900, 1200),
    palette: ["#E8B07A", "#C97B4E", "#F2DCB3", "#7A6A4C", "#3A2C1E"],
    filter: LR_FILTERS.warm_picnic,
    note: "Soft golden hour, picnic blanket light.",
    photos: [
      photo("girl-picnic-park"),
      photo("strawberries-bowl-table"),
      photo("yellow-flowers-field"),
      photo("dog-running-grass"),
      photo("vintage-camera-blanket"),
      photo("warm-coffee-morning"),
    ],
  },
  {
    id: "tokyo_night",
    name: "Tokyo Night",
    createdAt: "May 6",
    sample: photo("tokyo-shibuya-night-neon", 900, 1200),
    palette: ["#3B5A8C", "#C44A6B", "#1B1F2A", "#E0C28A", "#6F88B6"],
    filter: LR_FILTERS.tokyo_night,
    note: "Neon-on-asphalt, late-train moodboard.",
    photos: [
      photo("shinjuku-alley-lights"),
      photo("ramen-bowl-bar"),
      photo("rainy-street-neon-sign"),
      photo("train-station-tokyo"),
      photo("vending-machine-night"),
    ],
  },
  {
    id: "soft_green",
    name: "Soft Green",
    createdAt: "May 3",
    sample: photo("ferns-forest-morning", 900, 1200),
    palette: ["#A8B89A", "#5C7A5E", "#E5E8D8", "#3B4A38", "#C4B89A"],
    filter: LR_FILTERS.soft_green,
    note: "Studio Ghibli walk-in-the-woods.",
    photos: [
      photo("mossy-stones-creek"),
      photo("tea-cup-window-sill"),
      photo("linen-shirt-hang"),
      photo("kitchen-herbs-counter"),
    ],
  },
  {
    id: "creamy_street",
    name: "Creamy Street",
    createdAt: "Apr 28",
    sample: photo("paris-cafe-street", 900, 1200),
    palette: ["#E8DCC6", "#B69B7E", "#7A5E48", "#3A2C22", "#C8A78A"],
    filter: LR_FILTERS.creamy_street,
    note: "European film stock vibes.",
    photos: [
      photo("paris-balcony-flowers"),
      photo("croissant-coffee-marble"),
      photo("woman-vintage-coat"),
    ],
  },
  {
    id: "sunny_film",
    name: "Sunny Film",
    createdAt: "Apr 22",
    sample: photo("california-pool-summer", 900, 1200),
    palette: ["#F4D58D", "#E89B5A", "#7BB4D9", "#2E5F84", "#FFFBEF"],
    filter: LR_FILTERS.sunny_film,
    note: "California 35mm, almost too bright.",
    photos: [
      photo("pool-deck-summer"),
      photo("orange-juice-glass"),
      photo("beach-towel-sand"),
      photo("surfboard-leaning-wall"),
      photo("convertible-coast-road"),
      photo("ice-cream-melting"),
      photo("sunglasses-blue-sky"),
    ],
  },
  {
    id: "cozy_room",
    name: "Cozy Room",
    createdAt: "Apr 15",
    sample: photo("warm-lamp-bedroom-evening", 900, 1200),
    palette: ["#C28A5A", "#7A4A2E", "#E8C9A0", "#3A2418", "#A06B48"],
    filter: LR_FILTERS.cozy_room,
    note: "Lamp light, blanket, book on lap.",
    photos: [
      photo("reading-chair-lamp"),
      photo("candle-blanket-evening"),
      photo("dog-on-bed-warm"),
      photo("record-player-shelf"),
      photo("hot-chocolate-marshmallow"),
    ],
  },
];

/* candidate sample image used in the "Create" flow */
const LR_CREATE_SAMPLE = photo("vintage-roadtrip-mountain-sky", 900, 1200);
const LR_CREATE_PALETTE = ["#7AB0C9", "#E8C26A", "#C4885A", "#2A3F4E", "#F2E6D2"];

Object.assign(window, {
  LR_FILTERS, LR_ROLLS, LR_CREATE_SAMPLE, LR_CREATE_PALETTE, photo,
});
