// ============================================================
// YECO - التصنيفات (شبكة 2 أعمدة بصور وعدد المنتجات)
// ============================================================

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/store.dart';
import '../shared/widgets.dart';
import '../shell/shell.dart';
import 'product_list_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.storeOf(context);
    final cats = store.categories;
    return Scaffold(
      appBar: AppBar(
        title: const Text('التصنيفات'),
        actions: const [AccountButton()],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final c = cats[i];
          final color = Color(c.colorValue);
          final n = store.countByCategory[c.id] ?? 0;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductListPage(category: c)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImage(c.image, radius: 0),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  color.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          top: 8,
                          start: 8,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              categoryIcon(c.iconCode),
                              color: color,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Pill('$n', color: color),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: YecoColors.surface,
    );
  }
}
