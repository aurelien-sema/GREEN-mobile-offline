import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

/// Provider pour gérer les produits, catégories et commandes de la Marketplace
class MarketplaceProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();

  late List<CategoryModel> _categories;
  late List<ProductModel> _products;
  List<OrderModel> _orders = [];

  MarketplaceProvider() {
    _initializeData();
  }

  void _initializeData() {
    // Catégories
    _categories = [
      CategoryModel(
        id: 'cat_seeds',
        name: 'Semences & Plants',
        icon: '🌱',
        description: 'Semences et plants de qualité',
      ),
      CategoryModel(
        id: 'cat_fertilizers',
        name: 'Engrais & Amendements',
        icon: '🧴',
        description: 'Engrais et fertilisants',
      ),
      CategoryModel(
        id: 'cat_protection',
        name: 'Protection des cultures',
        icon: '🐛',
        description: 'Fongicides et insecticides',
      ),
      CategoryModel(
        id: 'cat_equipment',
        name: 'Équipements',
        icon: '🛠️',
        description: 'Outils et équipements agricoles',
      ),
    ];

    // Produits avec données réalistes et localisées pour le Cameroun
    _products = [
      // CATÉGORIE 1 : SEMENCES & PLANTS
      ProductModel(
        id: 'prod_001',
        name: 'Semences de Maïs Hybride Haut Rendement (20 kg)',
        categoryId: 'cat_seeds',
        description:
            'Semences de maïs hybride sélectionnées pour les conditions agroclimatiques camerounaises. Bon rendement, bonne résistance aux maladies courantes et cycle de croissance court.',
        shortDescription: 'Semences de maïs hybride – sac 20 kg',
        characteristics: [
          'Type : Maïs hybride',
          'Conditionnement : Sac de 20 kg',
          'Cycle : 90–110 jours',
          'Rendement potentiel : élevé',
          'Utilisation : culture de maïs pluvial',
        ],
        supplierName: 'Agri Planetary Co. Ltd',
        location: 'Limbe, Cameroun',
        priceMin: 25000,
        priceMax: 35000,
        imageUrl: 'assets/images/1 Semences de maïs hybride – SAC 20 kg.jpg',
        tags: ['maïs', 'hybride', 'rendement'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_002',
        name: 'Semences de Tomate Hybride F1 (Maraîchage)',
        categoryId: 'cat_seeds',
        description:
            'Semences de tomate hybride adaptées au maraîchage intensif. Fruits homogènes, bonne conservation et forte productivité.',
        shortDescription: 'Semences de tomate hybride F1',
        characteristics: [
          'Type : Hybride F1',
          'Utilisation : maraîchage',
          'Bonne tolérance aux maladies foliaires',
          'Adaptée aux climats tropicaux',
        ],
        supplierName: 'Musa Agro Ltd',
        location: 'Douala, Cameroun',
        priceMin: 5000,
        priceMax: 12000,
        imageUrl: 'assets/images/2 Semences de tomate hybride F1.jpg',
        tags: ['tomate', 'maraîchage', 'hybride'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_003',
        name: 'Boutures de Manioc Amélioré',
        categoryId: 'cat_seeds',
        description:
            'Boutures de manioc sélectionnées pour un bon rendement et une meilleure résistance aux maladies virales.',
        shortDescription: 'Boutures de manioc amélioré',
        characteristics: [
          'Type : Manioc amélioré',
          'Longueur bouture : 20–25 cm',
          'Utilisation : replantation',
          'Bon taux de reprise',
        ],
        supplierName: 'Coopératives agricoles locales',
        location: 'Sud & Littoral, Cameroun',
        priceMin: 100,
        priceMax: 300,
        imageUrl: 'assets/images/3 Boutures de manioc amélioré.jpg',
        tags: ['manioc', 'bouture', 'amélioré'],
        rating: 0,
        reviewCount: 0,
      ),

      // CATÉGORIE 2 : ENGRAIS & AMENDEMENTS
      ProductModel(
        id: 'prod_004',
        name: 'Engrais NPK 15-15-15 (50 kg)',
        categoryId: 'cat_fertilizers',
        description:
            'Engrais minéral complet favorisant la croissance, la floraison et la fructification des cultures.',
        shortDescription: 'Engrais NPK 15-15-15 – sac 50 kg',
        characteristics: [
          'Formulation : NPK 15-15-15',
          'Conditionnement : sac 50 kg',
          'Utilisation : maïs, tomate, manioc',
        ],
        supplierName: 'Distributeurs agréés MINADER',
        location: 'Douala / Yaoundé, Cameroun',
        priceMin: 25000,
        priceMax: 32000,
        imageUrl: 'assets/images/4 Engrais NPK 15-15-15 – sac 50 kg.jpg',
        tags: ['engrais', 'npk', 'minéral'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_005',
        name: 'Urée 46 % Azote (50 kg)',
        categoryId: 'cat_fertilizers',
        description:
            'Engrais azoté favorisant la croissance végétative rapide des cultures.',
        shortDescription: 'Urée 46 % – sac 50 kg',
        characteristics: [
          'Teneur : 46 % azote',
          'Conditionnement : sac 50 kg',
          'Usage : cultures vivrières',
        ],
        supplierName: 'Agrochem AC',
        location: 'Cameroun',
        priceMin: 23000,
        priceMax: 30000,
        imageUrl: 'assets/images/5 Urée 46 % – sac 50 kg.jpg',
        tags: ['urée', 'azote', 'engrais'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_006',
        name: 'Compost Organique Naturel (50 L)',
        categoryId: 'cat_fertilizers',
        description:
            'Compost issu de matières organiques locales, améliore la structure du sol et la fertilité à long terme.',
        shortDescription: 'Compost organique local',
        characteristics: [
          'Origine : déchets organiques / fumier traité',
          'Conditionnement : sac 50 L',
          '100 % naturel',
        ],
        supplierName: 'Coopératives agricoles locales',
        location: 'Cameroun',
        priceMin: 2000,
        priceMax: 4000,
        imageUrl: 'assets/images/6 Compost organique local.jpg',
        tags: ['compost', 'organique', 'naturel'],
        rating: 0,
        reviewCount: 0,
      ),

      // CATÉGORIE 3 : PROTECTION DES CULTURES
      ProductModel(
        id: 'prod_007',
        name: 'Nordox 75 WG – Fongicide à base de cuivre',
        categoryId: 'cat_protection',
        description:
            'Fongicide homologué pour la lutte contre les maladies fongiques des cultures.',
        shortDescription: 'Fongicide cuivre Nordox 75 WG',
        characteristics: [
          'Formulation : WG',
          'Usage : maladies foliaires',
          'Produit homologué MINADER',
        ],
        supplierName: 'Agrochem AC',
        location: 'Cameroun',
        priceMin: 6000,
        priceMax: 12000,
        imageUrl: 'assets/images/7 Fongicide cuivre Nordox 75 WG.webp',
        tags: ['fongicide', 'cuivre', 'maladies'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_008',
        name: 'PEGASUS 250 SC – Insecticide',
        categoryId: 'cat_protection',
        description:
            'Insecticide utilisé pour lutter contre les ravageurs des cultures maraîchères.',
        shortDescription: 'Insecticide PEGASUS 250 SC',
        characteristics: [
          'Formulation : SC',
          'Usage : insectes ravageurs',
          'Homologué MINADER',
        ],
        supplierName: 'Agrochem AC',
        location: 'Cameroun',
        priceMin: 8000,
        priceMax: 15000,
        imageUrl: 'assets/images/logo_green.png',
        tags: ['insecticide', 'ravageurs', 'protection'],
        rating: 0,
        reviewCount: 0,
      ),

      // CATÉGORIE 4 : ÉQUIPEMENTS
      ProductModel(
        id: 'prod_009',
        name: 'Pulvérisateur Manuel à Dos – 16 Litres',
        categoryId: 'cat_equipment',
        description:
            'Pulvérisateur manuel pour application de traitements phytosanitaires.',
        shortDescription: 'Pulvérisateur dorsal 16 L',
        characteristics: [
          'Capacité : 16 L',
          'Type : manuel',
          'Utilisation : maraîchage',
        ],
        supplierName: 'LykaTi Market',
        location: 'Cameroun',
        priceMin: 22000,
        priceMax: 35000,
        imageUrl: 'assets/images/logo_green.png',
        tags: ['pulvérisateur', 'équipement', 'manuel'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_010',
        name: 'Kit de Protection Agricole (Gants + Masque + Lunettes)',
        categoryId: 'cat_equipment',
        description:
            'Équipement de protection individuelle pour travaux agricoles et traitements phytosanitaires.',
        shortDescription: 'Kit EPI agricole',
        characteristics: [
          'Contenu : gants, lunettes, masque',
          'Réutilisable',
          'Sécurité agricole',
        ],
        supplierName: 'Agrochem AC',
        location: 'Cameroun',
        priceMin: 5000,
        priceMax: 10000,
        imageUrl: 'assets/images/10 Kit EPI agricole.webp',
        tags: ['protection', 'epi', 'sécurité'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_011',
        name: 'Plateau de Semis 50 Alvéoles',
        categoryId: 'cat_equipment',
        description:
            'Plateau utilisé pour la production de plants en pépinière.',
        shortDescription: 'Plateau de semis 50 alvéoles',
        characteristics: [
          'Nombre d\'alvéoles : 50',
          'Matériau : plastique rigide',
          'Réutilisable',
        ],
        supplierName: 'Agro-Hospital',
        location: 'Cameroun',
        priceMin: 2000,
        priceMax: 4000,
        imageUrl: 'assets/images/11 Plateau de semis 50 alvéoles.webp',
        tags: ['semis', 'pépinière', 'plateau'],
        rating: 0,
        reviewCount: 0,
      ),
      ProductModel(
        id: 'prod_012',
        name: 'Kit Irrigation Goutte-à-Goutte – Maraîchage',
        categoryId: 'cat_equipment',
        description:
            'Système simple d\'irrigation économique pour petites exploitations.',
        shortDescription: 'Kit irrigation goutte-à-goutte',
        characteristics: [
          'Type : goutte-à-goutte',
          'Nombre de sorties : 10–20',
          'Installation facile',
        ],
        supplierName: 'CAMCO Equipment Cameroon Ltd',
        location: 'Cameroun',
        priceMin: 30000,
        priceMax: 60000,
        imageUrl: 'https://www.facebook.com/camcocameroonltd/',
        tags: ['irrigation', 'goutte-à-goutte', 'économique'],
        rating: 0,
        reviewCount: 0,
      ),
    ];
  }

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<ProductModel> get products => List.unmodifiable(_products);
  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<ProductModel> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  ProductModel? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> placeOrder(String productId, int quantity) async {
    final product = getProductById(productId);
    if (product == null) return false;

    final order = OrderModel(
      id: _uuid.v4(),
      productId: productId,
      productName: product.name,
      quantity: quantity,
      price: product.price,
      totalPrice: product.price * quantity,
      orderedAt: DateTime.now(),
      status: 'pending',
    );

    _orders.insert(0, order);
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  int getOrderCount() => _orders.length;
}
