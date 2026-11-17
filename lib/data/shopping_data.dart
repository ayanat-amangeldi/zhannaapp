import '../language.dart';

enum ProductGroup {
  produce(
    LocalizedText('Овощи, фрукты и грибы', 'Көкөніс, жеміс және саңырауқұлақ'),
  ),
  protein(LocalizedText('Мясо, рыба и яйца', 'Ет, балық және жұмыртқа')),
  pantry(LocalizedText('Бакалея и хлеб', 'Бакалея және нан')),
  dairy(LocalizedText('Молочные продукты', 'Сүт өнімдері')),
  ready(LocalizedText('Готовые блюда', 'Дайын тағамдар'));

  const ProductGroup(this.label);
  final LocalizedText label;
}

enum WeightBasis {
  none(LocalizedText('', '')),
  raw(LocalizedText('сырой вес', 'шикі салмағы')),
  cooked(LocalizedText('готовый вес', 'піскен салмағы'));

  const WeightBasis(this.label);
  final LocalizedText label;
}

enum ProductUnit {
  g(LocalizedText('г', 'г')),
  kg(LocalizedText('кг', 'кг')),
  ml(LocalizedText('мл', 'мл')),
  l(LocalizedText('л', 'л')),
  pieces(LocalizedText('шт.', 'дана')),
  tsp(LocalizedText('ч. л.', 'шай қасық')),
  toTaste(LocalizedText('по вкусу', 'дәміне қарай'));

  const ProductUnit(this.label);
  final LocalizedText label;
  ProductUnit get canonical => switch (this) {
    kg => g,
    l => ml,
    _ => this,
  };
  int get multiplier => this == kg || this == l ? 1000 : 1;
}

class Product {
  const Product(this.id, this.group, this._ru, this._kk);
  final String id;
  final ProductGroup group;
  final String _ru;
  final String _kk;
  LocalizedText get name => LocalizedText(_ru, _kk);
}

class ShoppingIngredient {
  const ShoppingIngredient(
    this.product,
    this.amount, [
    this.unit = ProductUnit.g,
    this.basis = WeightBasis.none,
  ]);
  const ShoppingIngredient.toTaste(this.product)
    : amount = null,
      unit = ProductUnit.toTaste,
      basis = WeightBasis.none;
  final Product product;
  final num? amount;
  final ProductUnit unit;
  final WeightBasis basis;

  LocalizedText get quantityLabel {
    final value = amount;
    if (value == null) return unit.label;
    final number = value.toString().replaceAll('.', ',');
    final ruBasis = basis == WeightBasis.none ? '' : ' · ${basis.label.ru}';
    final kkBasis = basis == WeightBasis.none ? '' : ' · ${basis.label.kk}';
    return LocalizedText(
      '$number ${unit.label.ru}$ruBasis',
      '$number ${unit.label.kk}$kkBasis',
    );
  }

  LocalizedText get portionLabel => LocalizedText(
    '${product.name.ru} — ${quantityLabel.ru}',
    '${product.name.kk} — ${quantityLabel.kk}',
  );
}

class ShoppingRecipe {
  const ShoppingRecipe(this.ingredients, {this.incomplete = false});
  final List<ShoppingIngredient> ingredients;
  final bool incomplete;
}

const _produce = ProductGroup.produce;
const _protein = ProductGroup.protein;
const _pantry = ProductGroup.pantry;
const _dairy = ProductGroup.dairy;
const _ready = ProductGroup.ready;
const _g = ProductUnit.g;
const _pcs = ProductUnit.pieces;
const _tsp = ProductUnit.tsp;
const _cooked = WeightBasis.cooked;
const _raw = WeightBasis.raw;
const _cucumber = Product('cucumber', _produce, 'Огурец', 'Қияр');
const _tomato = Product('tomato', _produce, 'Помидор', 'Қызанақ');
const _carrot = Product('carrot', _produce, 'Морковь', 'Сәбіз');
const _cabbage = Product('cabbage', _produce, 'Капуста', 'Қырыққабат');
const _kraut = Product(
  'sauerkraut',
  _produce,
  'Квашеная капуста',
  'Ашытылған қырыққабат',
);
const _apple = Product('apple', _produce, 'Яблоко', 'Алма');
const _kiwi = Product('kiwi', _produce, 'Киви', 'Киви');
const _mandarin = Product('mandarin', _produce, 'Мандарин', 'Мандарин');
const _lettuce = Product(
  'lettuce_leaf',
  _produce,
  'Листья салата',
  'Салат жапырағы',
);
const _corn = Product(
  'canned_corn',
  _pantry,
  'Консервированная кукуруза',
  'Консервіленген жүгері',
);
const _rice = Product('rice', _pantry, 'Рис', 'Күріш');
const _buckwheat = Product('buckwheat', _pantry, 'Гречка', 'Қарақұмық');
const _beans = Product('beans', _pantry, 'Фасоль', 'Үрме бұршақ');
const _pasta = Product('pasta', _pantry, 'Макароны', 'Макарон');
const _bread = Product('black_bread', _pantry, 'Чёрный хлеб', 'Қара нан');
const _lavash = Product('lavash', _pantry, 'Лаваш', 'Лаваш');
const _oil = Product('olive_oil', _pantry, 'Оливковое масло', 'Зәйтүн майы');
const _garlic = Product('garlic', _produce, 'Чеснок', 'Сарымсақ');
const _vinegar = Product('vinegar', _pantry, 'Уксус', 'Сірке суы');
const _salt = Product('salt', _pantry, 'Соль', 'Тұз');
const _pepper = Product('pepper', _pantry, 'Перец', 'Бұрыш');
const _redPepper = Product(
  'red_pepper',
  _pantry,
  'Красный перец',
  'Қызыл бұрыш',
);
const _egg = Product('egg', _protein, 'Яйца', 'Жұмыртқа');
const _eggWhite = Product(
  'egg_white',
  _protein,
  'Яичные белки',
  'Жұмыртқаның ағы',
);
const _chicken = Product('chicken', _protein, 'Курица', 'Тауық еті');
const _sourCream = Product(
  'sour_cream_15',
  _dairy,
  'Сметана 15%',
  'Қаймақ 15%',
);
const _cheese = Product('cheese', _dairy, 'Сыр', 'Ірімшік');
const _curd = Product('curd_1_2', _dairy, 'Творог 1–2%', 'Сүзбе 1–2%');
const _yogurt = Product('yogurt_1_2', _dairy, 'Йогурт 1,2%', 'Йогурт 1,2%');

const _fish = Product('fish', _protein, 'Рыба', 'Балық');
const _potato = Product('potato', _produce, 'Картофель', 'Картоп');
const _beef = Product('beef', _protein, 'Говядина', 'Сиыр еті');
const _onion = Product('onion', _produce, 'Лук', 'Пияз');
const _beet = Product('beet', _produce, 'Свёкла', 'Қызылша');
const _pumpkin = Product('pumpkin', _produce, 'Тыква', 'Асқабақ');
const _mustard = Product('mustard', _pantry, 'Горчица', 'Қыша');
const _chickenSkewers = Product(
  'chicken_skewers',
  _ready,
  'Куриный шашлык',
  'Тауық етінен кәуап',
);
const _chickenCutlets = Product(
  'chicken_cutlets',
  _ready,
  'Куриные котлеты',
  'Тауық етінен котлет',
);
const _ayran = Product('ayran_2_5', _dairy, 'Айран 2,5%', 'Айран 2,5%');
const _raisins = Product('raisins', _pantry, 'Изюм', 'Мейіз');
const _apricots = Product('dried_apricots', _pantry, 'Курага', 'Кепкен өрік');
const _prunes = Product('prunes', _pantry, 'Чернослив', 'Кепкен қара өрік');
const _peas = Product(
  'canned_peas',
  _pantry,
  'Консервированный зелёный горошек',
  'Консервіленген жасыл асбұршақ',
);

const _oats = Product('oats', _pantry, 'Овсяная крупа', 'Сұлы жармасы');
const _milk = Product('milk', _dairy, 'Молоко', 'Сүт');
const _milk25 = Product('milk_2_5', _dairy, 'Молоко 2,5%', 'Сүт 2,5%');
const _sweetener = Product(
  'sweetener',
  _pantry,
  'Заменитель сахара',
  'Қант алмастырғыш',
);
const _twix = Product('twix', _pantry, 'Twix', 'Twix');
const _banana = Product('banana', _produce, 'Банан', 'Банан');
const _walnuts = Product('walnuts', _pantry, 'Грецкие орехи', 'Грек жаңғағы');
const _hazelnutChocolate = Product(
  'alpen_gold_hazelnut',
  _pantry,
  'Alpen Gold с фундуком',
  'Орман жаңғағы қосылған Alpen Gold',
);
const _pancakes = Product(
  'banana_pancakes',
  _ready,
  'Банановые панкейки',
  'Банан панкейктері',
);
const _almonds = Product('almonds', _pantry, 'Миндаль', 'Бадам');
const _milkyWay = Product('milky_way', _pantry, 'Milky Way', 'Milky Way');
const _lavashPocket = Product(
  'lavash_pocket',
  _ready,
  'Конверт из лаваша с творогом и сыром',
  'Сүзбе мен ірімшік салынған лаваш конверті',
);
const _kinder = Product(
  'kinder_milk_slice',
  _pantry,
  'Kinder Ломтик',
  'Kinder Ломтик',
);
const _yogurtRange = Product(
  'yogurt_1_to_2',
  _dairy,
  'Йогурт 1–2%',
  'Йогурт 1–2%',
);
const _kazakhstanChocolate = Product(
  'kazakhstan_chocolate',
  _pantry,
  'Шоколад «Казахстан»',
  '«Қазақстан» шоколады',
);

// Для составных блюд без подтверждённого выхода на порцию сохраняем
// готовую позицию. Не прибавляем одновременно её состав из рецепта.
const shoppingRecipes = {
  'lunch_01': ShoppingRecipe([
    ShoppingIngredient(
      Product('goulash', _ready, 'ПП-гуляш', 'ПП-гуляш'),
      100,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_rice, 100, _g, _cooked),
    ShoppingIngredient(_cucumber, 100, _g, _raw),
    ShoppingIngredient(_tomato, 100, _g, _raw),
    ShoppingIngredient(_corn, 100),
    ShoppingIngredient(_egg, 1, _pcs, _cooked),
    ShoppingIngredient(_bread, 20),
  ], incomplete: true),
  'lunch_02': ShoppingRecipe([
    ShoppingIngredient(
      Product(
        'philadelphia',
        _ready,
        'Суши «Филадельфия»',
        '«Филадельфия» сушиі',
      ),
      6,
      _pcs,
    ),
    ShoppingIngredient(_chicken, 100, _g, _cooked),
    ShoppingIngredient(_kraut, 150),
    ShoppingIngredient(_buckwheat, 100, _g, _cooked),
    ShoppingIngredient.toTaste(_salt),
    ShoppingIngredient.toTaste(_redPepper),
  ]),
  'lunch_03': ShoppingRecipe([
    ShoppingIngredient(
      Product('borscht', _ready, 'Борщ с курицей', 'Тауық еті қосылған борщ'),
      500,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_carrot, 150, _g, _raw),
    ShoppingIngredient(_oil, 1, _tsp),
    ShoppingIngredient.toTaste(_garlic),
    ShoppingIngredient.toTaste(_vinegar),
    ShoppingIngredient(_beans, 100, _g, _cooked),
    ShoppingIngredient(_eggWhite, 1, _pcs, _cooked),
    ShoppingIngredient(_bread, 20),
  ], incomplete: true),
  'lunch_04': ShoppingRecipe([
    ShoppingIngredient(_chickenSkewers, 150, _g, _cooked),
    ShoppingIngredient(
      Product(
        'mushroom_skewers',
        _ready,
        'Шашлык из шампиньонов',
        'Қозықұйрықтан кәуап',
      ),
      150,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_cucumber, 100, _g, _raw),
    ShoppingIngredient(_tomato, 100, _g, _raw),
    ShoppingIngredient(_kiwi, 200, _g, _raw),
  ], incomplete: true),
  'lunch_05': ShoppingRecipe([
    ShoppingIngredient(
      Product(
        'mixed_cutlets',
        _ready,
        'Котлеты из говядины и курицы',
        'Сиыр және тауық етінен котлеттер',
      ),
      150,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_pasta, 150, _g, _cooked),
    ShoppingIngredient(_kraut, 200),
    ShoppingIngredient(_mandarin, 100, _g, _raw),
  ], incomplete: true),
  'lunch_06': ShoppingRecipe([
    ShoppingIngredient(
      Product('beef_soup', _ready, 'Говяжий суп', 'Сиыр етінен сорпа'),
      500,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_cabbage, 150, _g, _raw),
    ShoppingIngredient(_carrot, 100, _g, _raw),
    ShoppingIngredient(_tomato, 100, _g, _raw),
    ShoppingIngredient(_oil, 1, _tsp),
    ShoppingIngredient(_chicken, 100, _g, _cooked),
    ShoppingIngredient(_apple, 100, _g, _raw),
    ShoppingIngredient.toTaste(_salt),
    ShoppingIngredient.toTaste(_pepper),
    ShoppingIngredient.toTaste(_vinegar),
  ], incomplete: true),
  'lunch_07': ShoppingRecipe([
    ShoppingIngredient(
      Product(
        'orama',
        _ready,
        'Орама с говядиной и картофелем',
        'Сиыр еті мен картоп қосылған орама',
      ),
      150,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_kraut, 150),
    ShoppingIngredient(_eggWhite, 2, _pcs, _cooked),
    ShoppingIngredient(_beans, 50, _g, _cooked),
  ], incomplete: true),
  'lunch_08': ShoppingRecipe([
    ShoppingIngredient(
      Product('chicken_soup', _ready, 'Куриный суп', 'Тауық етінен сорпа'),
      500,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_cucumber, 100, _g, _raw),
    ShoppingIngredient(_tomato, 100, _g, _raw),
    ShoppingIngredient(_bread, 20),
    ShoppingIngredient(_curd, 100),
    ShoppingIngredient(_yogurt, 50),
  ], incomplete: true),
  'lunch_09': ShoppingRecipe([
    ShoppingIngredient(_lavash, 1, _pcs),
    ShoppingIngredient(_chicken, 100, _g, _cooked),
    ShoppingIngredient(_cucumber, 50, _g, _raw),
    ShoppingIngredient(_tomato, 50, _g, _raw),
    ShoppingIngredient(_sourCream, 30),
    ShoppingIngredient(_cheese, 20),
    ShoppingIngredient(_lettuce, 2, _pcs),
    ShoppingIngredient.toTaste(_salt),
    ShoppingIngredient.toTaste(_redPepper),
  ]),
  'lunch_10': ShoppingRecipe([
    ShoppingIngredient(
      Product('fish_soup', _ready, 'Уха', 'Балық сорпасы'),
      500,
      _g,
      _cooked,
    ),
    ShoppingIngredient(
      Product('crab_salad', _ready, 'Крабовый салат', 'Краб салаты'),
      290,
      _g,
      _cooked,
    ),
    ShoppingIngredient(_bread, 20),
    ShoppingIngredient(_apple, 150, _g, _raw),
  ], incomplete: true),
  'dinner_01': ShoppingRecipe([
    ShoppingIngredient(_fish, 170, _g, _raw),
    ShoppingIngredient(_potato, 130, _g, _cooked),
    ShoppingIngredient(_kraut, 150),
    ShoppingIngredient.toTaste(_salt),
    ShoppingIngredient.toTaste(_pepper),
  ]),
  'dinner_02': ShoppingRecipe([
    ShoppingIngredient(_beef, 100, _g, _cooked),
    ShoppingIngredient(_tomato, 150, _g, _raw),
    ShoppingIngredient(_cucumber, 150, _g, _raw),
    ShoppingIngredient(_onion, 20, _g, _raw),
    ShoppingIngredient.toTaste(_salt),
    ShoppingIngredient.toTaste(_pepper),
  ]),
  'dinner_03': ShoppingRecipe([
    ShoppingIngredient(_chicken, 100, _g, _cooked),
    ShoppingIngredient(_buckwheat, 100, _g, _cooked),
    ShoppingIngredient(_beet, 150, _g, _cooked),
  ]),
  'dinner_04': ShoppingRecipe([
    ShoppingIngredient(_chickenSkewers, 100, _g, _cooked),
    ShoppingIngredient(_kraut, 200),
    ShoppingIngredient(_pumpkin, 120, _g, _cooked),
  ], incomplete: true),
  'dinner_05': ShoppingRecipe([
    ShoppingIngredient(_egg, 2, _pcs, _cooked),
    ShoppingIngredient(_beans, 100, _g, _cooked),
    ShoppingIngredient(_cucumber, 100, _g, _raw),
    ShoppingIngredient(_tomato, 100, _g, _raw),
  ]),
  'dinner_06': ShoppingRecipe([
    ShoppingIngredient(_cabbage, 100, _g, _raw),
    ShoppingIngredient(_chicken, 100, _g, _cooked),
    ShoppingIngredient(_egg, 1, _pcs, _cooked),
    ShoppingIngredient(_cheese, 15),
    ShoppingIngredient(_tomato, 100, _g, _raw),
    ShoppingIngredient(_sourCream, 50),
    ShoppingIngredient(_mustard, 5),
    ShoppingIngredient.toTaste(_salt),
    ShoppingIngredient.toTaste(_pepper),
  ]),
  'dinner_07': ShoppingRecipe([
    ShoppingIngredient(_chickenCutlets, 100, _g, _cooked),
    ShoppingIngredient(_pumpkin, 150, _g, _cooked),
    ShoppingIngredient(_beet, 150, _g, _cooked),
  ], incomplete: true),
  'dinner_08': ShoppingRecipe([
    ShoppingIngredient(_ayran, 200, ProductUnit.ml),
    ShoppingIngredient(_egg, 2, _pcs, _cooked),
    ShoppingIngredient(_raisins, 25),
  ]),
  'dinner_09': ShoppingRecipe([
    ShoppingIngredient(_curd, 180),
    ShoppingIngredient(_sourCream, 30),
    ShoppingIngredient(_apricots, 30),
    ShoppingIngredient(_prunes, 30),
  ]),
  'dinner_10': ShoppingRecipe([
    ShoppingIngredient(_tomato, 100, _g, _raw),
    ShoppingIngredient(_peas, 50),
    ShoppingIngredient(_beans, 80, _g, _cooked),
    ShoppingIngredient(_cucumber, 100, _g, _raw),
    ShoppingIngredient(_egg, 2, _pcs, _cooked),
    ShoppingIngredient.toTaste(_salt),
    ShoppingIngredient.toTaste(_pepper),
  ]),
  'breakfast_01': ShoppingRecipe([
    ShoppingIngredient(_oats, 35, _g, _raw),
    ShoppingIngredient(_milk, 80, ProductUnit.ml),
    ShoppingIngredient.toTaste(_sweetener),
    ShoppingIngredient(_eggWhite, 4, _pcs, _cooked),
    ShoppingIngredient(_twix, 20),
  ]),
  'breakfast_02': ShoppingRecipe([
    ShoppingIngredient(_kiwi, 50, _g, _raw),
    ShoppingIngredient(_banana, 50, _g, _raw),
    ShoppingIngredient(_apple, 50, _g, _raw),
    ShoppingIngredient(_curd, 130),
    ShoppingIngredient(_yogurt, 150),
    ShoppingIngredient(_walnuts, 10),
  ]),
  'breakfast_03': ShoppingRecipe([
    ShoppingIngredient(_egg, 2, _pcs, _raw),
    ShoppingIngredient(_cucumber, 100, _g, _raw),
    ShoppingIngredient(_tomato, 100, _g, _raw),
    ShoppingIngredient(_beans, 70, _g, _cooked),
    ShoppingIngredient(_hazelnutChocolate, 20),
  ]),
  'breakfast_04': ShoppingRecipe([
    ShoppingIngredient(_pancakes, 150, _g, _cooked),
    ShoppingIngredient(_curd, 130),
    ShoppingIngredient(_almonds, 10),
  ], incomplete: true),
  'breakfast_05': ShoppingRecipe([
    ShoppingIngredient(_chicken, 50, _g, _cooked),
    ShoppingIngredient(_bread, 40),
    ShoppingIngredient(_sourCream, 10),
    ShoppingIngredient(_lettuce, 1, _pcs),
    ShoppingIngredient(_tomato, 20, _g, _raw),
    ShoppingIngredient(_egg, 1, _pcs, _raw),
    ShoppingIngredient(_milkyWay, 26),
  ]),
  'breakfast_06': ShoppingRecipe([
    ShoppingIngredient(_lavashPocket, 200, _g, _cooked),
  ], incomplete: true),
  'breakfast_07': ShoppingRecipe([
    ShoppingIngredient(_rice, 30, _g, _raw),
    ShoppingIngredient(_milk, 80, ProductUnit.ml),
    ShoppingIngredient.toTaste(_sweetener),
    ShoppingIngredient(_curd, 150),
    ShoppingIngredient(_kinder, 28),
  ]),
  'breakfast_08': ShoppingRecipe([
    ShoppingIngredient(_curd, 150),
    ShoppingIngredient(_banana, 100, _g, _raw),
    ShoppingIngredient(_yogurtRange, 100),
    ShoppingIngredient(_kazakhstanChocolate, 20),
  ]),
  'breakfast_09': ShoppingRecipe([
    ShoppingIngredient(_lavash, 1, _pcs),
    ShoppingIngredient(_cucumber, 50, _g, _raw),
    ShoppingIngredient(_tomato, 50, _g, _raw),
    ShoppingIngredient(_egg, 2, _pcs, _cooked),
    ShoppingIngredient(_sourCream, 20),
    ShoppingIngredient(_beans, 30, _g, _cooked),
    ShoppingIngredient(_prunes, 20),
  ]),
  'breakfast_10': ShoppingRecipe([
    ShoppingIngredient(_egg, 3, _pcs, _raw),
    ShoppingIngredient(_milk25, 50, ProductUnit.ml),
    ShoppingIngredient(_tomato, 50, _g, _raw),
    ShoppingIngredient(_bread, 20),
    ShoppingIngredient(_buckwheat, 100, _g, _cooked),
  ]),
};
