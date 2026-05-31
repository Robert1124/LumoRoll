// lutroll-data.jsx — sample rolls, photos, and LUT filter recipes

const LR_PHOTO_MAP = {
  "https://picsum.photos/seed/picnic-basket-grass/900/1200": "p_picnic_basket_grass",
  "https://picsum.photos/seed/girl-picnic-park/800/800": "p_girl_picnic_park",
  "https://picsum.photos/seed/strawberries-bowl-table/800/800": "p_strawberries_bowl_table",
  "https://picsum.photos/seed/yellow-flowers-field/800/800": "p_yellow_flowers_field",
  "https://picsum.photos/seed/dog-running-grass/800/800": "p_dog_running_grass",
  "https://picsum.photos/seed/vintage-camera-blanket/800/800": "p_vintage_camera_blanket",
  "https://picsum.photos/seed/warm-coffee-morning/800/800": "p_warm_coffee_morning",
  "https://picsum.photos/seed/tokyo-shibuya-night-neon/900/1200": "p_tokyo_shibuya_night_neon",
  "https://picsum.photos/seed/shinjuku-alley-lights/800/800": "p_shinjuku_alley_lights",
  "https://picsum.photos/seed/ramen-bowl-bar/800/800": "p_ramen_bowl_bar",
  "https://picsum.photos/seed/rainy-street-neon-sign/800/800": "p_rainy_street_neon_sign",
  "https://picsum.photos/seed/train-station-tokyo/800/800": "p_train_station_tokyo",
  "https://picsum.photos/seed/vending-machine-night/800/800": "p_vending_machine_night",
  "https://picsum.photos/seed/ferns-forest-morning/900/1200": "p_ferns_forest_morning",
  "https://picsum.photos/seed/mossy-stones-creek/800/800": "p_mossy_stones_creek",
  "https://picsum.photos/seed/tea-cup-window-sill/800/800": "p_tea_cup_window_sill",
  "https://picsum.photos/seed/linen-shirt-hang/800/800": "p_linen_shirt_hang",
  "https://picsum.photos/seed/kitchen-herbs-counter/800/800": "p_kitchen_herbs_counter",
  "https://picsum.photos/seed/paris-cafe-street/900/1200": "p_paris_cafe_street",
  "https://picsum.photos/seed/paris-balcony-flowers/800/800": "p_paris_balcony_flowers",
  "https://picsum.photos/seed/croissant-coffee-marble/800/800": "p_croissant_coffee_marble",
  "https://picsum.photos/seed/woman-vintage-coat/800/800": "p_woman_vintage_coat",
  "https://picsum.photos/seed/california-pool-summer/900/1200": "p_california_pool_summer",
  "https://picsum.photos/seed/pool-deck-summer/800/800": "p_pool_deck_summer",
  "https://picsum.photos/seed/orange-juice-glass/800/800": "p_orange_juice_glass",
  "https://picsum.photos/seed/beach-towel-sand/800/800": "p_beach_towel_sand",
  "https://picsum.photos/seed/surfboard-leaning-wall/800/800": "p_surfboard_leaning_wall",
  "https://picsum.photos/seed/convertible-coast-road/800/800": "p_convertible_coast_road",
  "https://picsum.photos/seed/ice-cream-melting/800/800": "p_ice_cream_melting",
  "https://picsum.photos/seed/sunglasses-blue-sky/800/800": "p_sunglasses_blue_sky",
  "https://picsum.photos/seed/warm-lamp-bedroom-evening/900/1200": "p_warm_lamp_bedroom_evening",
  "https://picsum.photos/seed/reading-chair-lamp/800/800": "p_reading_chair_lamp",
  "https://picsum.photos/seed/candle-blanket-evening/800/800": "p_candle_blanket_evening",
  "https://picsum.photos/seed/dog-on-bed-warm/800/800": "p_dog_on_bed_warm",
  "https://picsum.photos/seed/record-player-shelf/800/800": "p_record_player_shelf",
  "https://picsum.photos/seed/hot-chocolate-marshmallow/800/800": "p_hot_chocolate_marshmallow",
  "https://picsum.photos/seed/vintage-roadtrip-mountain-sky/900/1200": "p_vintage_roadtrip_mountain_sky",
  "https://picsum.photos/seed/apply-window-light-coffee/900/1200": "p_apply_window_light_coffee",
  "https://picsum.photos/seed/apply-cyclist-empty-street/900/1200": "p_apply_cyclist_empty_street",
  "https://picsum.photos/seed/apply-cake-on-plate/900/1200": "p_apply_cake_on_plate",
  "https://picsum.photos/seed/apply-woman-window-laptop/900/1200": "p_apply_woman_window_laptop"
};

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
const photo = (seed, w = 800, h = 800) => {
  const url = `https://picsum.photos/seed/${seed}/${w}/${h}`;
  const id = LR_PHOTO_MAP[url];
  return (id && window.__resources && window.__resources[id]) || url;
};

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
