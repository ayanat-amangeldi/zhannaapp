import 'package:flutter/material.dart';

import '../data/shopping_data.dart';
import '../language.dart';

class RecipeIngredientsScreen extends StatefulWidget {
  const RecipeIngredientsScreen({
    super.key,
    required this.initial,
    required this.products,
  });

  final ShoppingRecipe? initial;
  final List<Product> products;

  @override
  State<RecipeIngredientsScreen> createState() =>
      _RecipeIngredientsScreenState();
}

class _RecipeIngredientsScreenState extends State<RecipeIngredientsScreen> {
  late final _items = [...?widget.initial?.ingredients];
  late bool _incomplete = widget.initial?.incomplete ?? false;

  Future<void> _edit([int? index]) async {
    final productMap = <String, Product>{
      for (final product in widget.products) product.id: product,
      for (final item in _items) item.product.id: item.product,
    };
    final ingredient = await Navigator.of(context).push<ShoppingIngredient>(
      MaterialPageRoute(
        builder: (_) => _IngredientForm(
          products: productMap.values.toList(),
          initial: index == null ? null : _items[index],
        ),
      ),
    );
    if (!mounted || ingredient == null) return;
    setState(() {
      if (index == null) {
        _items.add(ingredient);
      } else {
        _items[index] = ingredient;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        context.tr('Ингредиенты для покупок', 'Сатып алуға арналған өнімдер'),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.tr(
            'Укажи продукты и количества на одно приготовление.',
            'Бір рет дайындауға қажет өнімдер мен мөлшерін көрсет.',
          ),
        ),
        const SizedBox(height: 12),
        for (final (index, item) in _items.indexed)
          Card(
            child: ListTile(
              title: Text(item.product.name.resolve(context)),
              subtitle: Text(item.quantityLabel.resolve(context)),
              onTap: () => _edit(index),
              trailing: IconButton(
                tooltip: context.tr('Удалить ингредиент', 'Өнімді алып тастау'),
                onPressed: () => setState(() => _items.removeAt(index)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: Text(context.tr('Добавить ингредиент', 'Өнім қосу')),
        ),
        SwitchListTile(
          title: Text(context.tr('Список неполный', 'Тізім толық емес')),
          subtitle: Text(
            context.tr(
              'Включи, если количество или состав части продуктов неизвестны.',
              'Кей өнімдердің мөлшері немесе құрамы белгісіз болса, қос.',
            ),
          ),
          value: _incomplete,
          onChanged: (value) => setState(() => _incomplete = value),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _items.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  ShoppingRecipe(
                    List.unmodifiable(_items),
                    incomplete: _incomplete,
                  ),
                ),
          child: Text(context.tr('Применить', 'Қолдану')),
        ),
      ),
    ),
  );
}

class _IngredientForm extends StatefulWidget {
  const _IngredientForm({required this.products, this.initial});

  final List<Product> products;
  final ShoppingIngredient? initial;

  @override
  State<_IngredientForm> createState() => _IngredientFormState();
}

class _IngredientFormState extends State<_IngredientForm> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.initial?.amount?.toString().replaceAll('.', ','),
  );
  final _ru = TextEditingController();
  final _kk = TextEditingController();
  late Product? _product = widget.initial?.product;
  late ProductUnit _unit = widget.initial?.unit ?? ProductUnit.g;
  late WeightBasis _basis = widget.initial?.basis ?? WeightBasis.none;
  ProductGroup _group = ProductGroup.produce;
  bool _newProduct = false;

  num? get _quantity => num.tryParse(_amount.text.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    _amount.dispose();
    _ru.dispose();
    _kk.dispose();
    super.dispose();
  }

  String? _requiredText(String? text) => (text?.trim().isEmpty ?? true)
      ? context.tr('Заполни поле', 'Өрісті толтыр')
      : null;

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Product? product = _product;
    if (_newProduct) {
      final ru = _ru.text.trim();
      final kk = _kk.text.trim();
      product =
          widget.products
              .where(
                (product) =>
                    product.name.ru.toLowerCase() == ru.toLowerCase() &&
                    product.name.kk.toLowerCase() == kk.toLowerCase(),
              )
              .firstOrNull ??
          Product(
            'local_product_${DateTime.now().microsecondsSinceEpoch}',
            _group,
            ru,
            kk,
          );
    }
    if (product == null) return;
    Navigator.of(context).pop(
      _unit == ProductUnit.toTaste
          ? ShoppingIngredient.toTaste(product)
          : ShoppingIngredient(product, _quantity!, _unit, _basis),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = [...widget.products]
      ..sort(
        (a, b) => a.name
            .resolve(context)
            .toLowerCase()
            .compareTo(b.name.resolve(context).toLowerCase()),
      );
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Ингредиент', 'Өнім'))),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                title: Text(context.tr('Новый продукт', 'Жаңа өнім')),
                value: _newProduct,
                onChanged: (value) => setState(() => _newProduct = value),
              ),
              if (_newProduct) ...[
                TextFormField(
                  controller: _ru,
                  decoration: InputDecoration(
                    labelText: context.tr('Название по-русски', 'Орысша атауы'),
                  ),
                  validator: _requiredText,
                ),
                TextFormField(
                  controller: _kk,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      'Название по-казахски',
                      'Қазақша атауы',
                    ),
                  ),
                  validator: _requiredText,
                ),
                DropdownButtonFormField<ProductGroup>(
                  initialValue: _group,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Категория продукта', 'Өнім санаты'),
                  ),
                  items: [
                    for (final group in ProductGroup.values)
                      DropdownMenuItem(
                        value: group,
                        child: Text(group.label.resolve(context)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _group = value!),
                ),
              ] else
                DropdownButtonFormField<String>(
                  initialValue: _product?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Продукт', 'Өнім'),
                  ),
                  items: [
                    for (final product in products)
                      DropdownMenuItem(
                        value: product.id,
                        child: Text(
                          product.name.resolve(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) => setState(
                    () => _product = products.firstWhere(
                      (product) => product.id == id,
                    ),
                  ),
                  validator: (id) => id == null
                      ? context.tr('Выбери продукт', 'Өнімді таңда')
                      : null,
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProductUnit>(
                initialValue: _unit,
                decoration: InputDecoration(
                  labelText: context.tr('Единица измерения', 'Өлшем бірлігі'),
                ),
                items: [
                  for (final unit in ProductUnit.values)
                    DropdownMenuItem(
                      value: unit,
                      child: Text(unit.label.resolve(context)),
                    ),
                ],
                onChanged: (value) => setState(() => _unit = value!),
              ),
              if (_unit != ProductUnit.toTaste) ...[
                TextFormField(
                  key: const ValueKey('ingredient-amount'),
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('Количество', 'Мөлшері'),
                  ),
                  validator: (_) {
                    final amount = _quantity;
                    return amount == null || !amount.isFinite || amount <= 0
                        ? context.tr(
                            'Введи число больше нуля',
                            'Нөлден үлкен сан енгіз',
                          )
                        : null;
                  },
                ),
                DropdownButtonFormField<WeightBasis>(
                  initialValue: _basis,
                  decoration: InputDecoration(
                    labelText: context.tr('Основание веса', 'Салмақ түрі'),
                  ),
                  items: [
                    for (final basis in WeightBasis.values)
                      DropdownMenuItem(
                        value: basis,
                        child: Text(
                          basis == WeightBasis.none
                              ? context.tr('Не указано', 'Көрсетілмеген')
                              : basis.label.resolve(context),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _basis = value!),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(
                  context.tr('Сохранить ингредиент', 'Өнімді сақтау'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
