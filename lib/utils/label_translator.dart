class LabelTranslator {
  static final Map<String, String> _plants = {
    'Apple': 'Pomme',
    'Blueberry': 'Myrtille',
    'Cherry': 'Cerise',
    'Cherry_(including_sour)': 'Cerise', 
    'Corn': 'Maïs',
    'Corn_(maize)': 'Maïs',
    'Grape': 'Raisin',
    'Orange': 'Orange',
    'Peach': 'Pêche',
    'Pepper': 'Poivron',
    'Pepper_bell': 'Poivron',
    'Potato': 'Pomme de terre',
    'Raspberry': 'Framboise',
    'Soybean': 'Soja',
    'Squash': 'Courge',
    'Strawberry': 'Fraise',
    'Tomato': 'Tomate',
  };

  static final Map<String, String> _diseases = {
    'Apple_scab': 'Tavelure',
    'Black_rot': 'Pourriture noire',
    'Cedar_apple_rust': 'Rouille du cèdre',
    'healthy': 'Saine',
    'Powdery_mildew': 'Oïdium',
    'Powedery_mildew': 'Oïdium', // Typo in dataset
    'Cercospora_leaf_spot': 'Tache cercosporéenne',
    'Gray_leaf_spot': 'Tache grise',
    'Common_rust': 'Rouille commune',
    'Common_rust_': 'Rouille commune',
    'Northern_Leaf_Blight': 'Helminthosporiose',
    'Esca': 'Esca',
    'Esca_(Black_Measles)': 'Esca',
    'Leaf_blight': 'Brûlure foliaire',
    'Leaf_blight_(Isariopsis_Leaf_Spot)': 'Brûlure foliaire',
    'Haunglongbing': 'Maladie du dragon jaune',
    'Haunglongbing_(Citrus_greening)': 'Maladie du dragon jaune',
    'Bacterial_spot': 'Tache bactérienne',
    'Early_blight': 'Alternariose',
    'Late_blight': 'Mildiou',
    'Leaf_scorch': 'Brûlure des feuilles',
    'Leaf_Mold': 'Moisissure des feuilles',
    'Septoria_leaf_spot': 'Septoriose',
    'Spider_mites': 'Acariens',
    'Two-spotted_spider_mite': 'Acariens',
    'Spider_mites Two-spotted_spider_mite': 'Acariens',
    'Target_Spot': 'Tache cible',
    'Yellow_Leaf_Curl_Virus': 'Virus des feuilles jaunes',
    'Tomato_Yellow_Leaf_Curl_Virus': 'Virus des feuilles jaunes',
    'Tomato_mosaic_virus': 'Virus de la mosaïque',
    'mosaic_virus': 'Virus de la mosaïque',
  };

  static Map<String, String> translate(String rawLabel) {
    // Expected format: Plant___Disease
    final parts = rawLabel.split('___');
    if (parts.isEmpty) return {'plant': 'Inconnue', 'disease': 'Inconnue'};

    final rawPlant = parts[0];
    final rawDisease = parts.length > 1 ? parts[1] : 'Inconnue';

    final plantWrapper = _plants.entries.firstWhere(
      (e) => rawPlant.contains(e.key),
      orElse: () => MapEntry(rawPlant, rawPlant),
    );
    final translatedPlant = _plants[rawPlant] ?? plantWrapper.value;

    // Handle "healthy" case specifically
    if (rawDisease.toLowerCase() == 'healthy') {
      return {'plant': translatedPlant, 'disease': 'Aucune (Saine)'};
    }

    // Try to find disease translation
    String translatedDisease = rawDisease.replaceAll('_', ' ');
    // Simple lookup
    if (_diseases.containsKey(rawDisease)) {
        translatedDisease = _diseases[rawDisease]!;
    } else {
        // substring matching
        for (final key in _diseases.keys) {
            if (rawDisease.contains(key)) {
                translatedDisease = _diseases[key]!;
                break;
            }
        }
    }

    return {'plant': translatedPlant, 'disease': translatedDisease};
  }
}
