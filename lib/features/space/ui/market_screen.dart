import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/domain/commodity.dart';
import '../../../core/domain/market.dart';
import '../../../core/domain/player_state.dart';
import '../../../shared/theme/app_colors.dart';

class MarketScreen extends StatefulWidget {
  final SystemMarket market;
  final PlayerState player;
  final VoidCallback onClose;

  const MarketScreen({
    super.key,
    required this.market,
    required this.player,
    required this.onClose,
  });

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

enum _StationTab { markt, bar, werft, missionen, klonKlinik }

class _MarketScreenState extends State<MarketScreen> {
  _StationTab _tab = _StationTab.markt;
  MarketListing? _selected;
  double _qty = 1;
  bool _isBuying = true;
  String? _feedback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Sticky header
          _StationAppBar(onClose: widget.onClose),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Hero area
                _HeroArea(),

                // Station tabs
                _TabRow(
                  selected: _tab,
                  onSelect: (t) => setState(() {
                    _tab = t;
                    _selected = null;
                  }),
                ),

                // Content per tab
                if (_tab == _StationTab.markt) ...[
                  _MarketListHeader(),
                  ..._buildListings(),
                  if (_feedback != null)
                    _Feedback(message: _feedback!),
                  if (_selected != null)
                    _TradePanel(
                      listing: _selected!,
                      market: widget.market,
                      player: widget.player,
                      qty: _qty.round(),
                      isBuying: _isBuying,
                      onQtyChanged: (v) => setState(() => _qty = v),
                      onToggleMode: () => setState(() => _isBuying = !_isBuying),
                      onBuy: _executeBuy,
                      onSell: _executeSell,
                    ),
                ] else
                  _TabPlaceholder(tab: _tab),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom status bar
          _StatusBar(player: widget.player),
        ],
      ),
    );
  }

  List<Widget> _buildListings() {
    final listings = widget.market.listings;
    return listings.map((l) {
      return _ListingRow(
        listing: l,
        market: widget.market,
        selected: _selected?.commodity.id == l.commodity.id,
        player: widget.player,
        onTap: () => setState(() {
          _selected = l;
          _qty = 1;
        }),
      );
    }).toList();
  }

  void _executeBuy() {
    if (_selected == null) return;
    setState(() {
      final result = widget.player.buy(_selected!, _qty.round());
      _feedback = switch (result) {
        BuyResult.success =>
          'Gekauft: ${_qty.round()} × ${_selected!.commodity.name}',
        BuyResult.insufficientCredits => 'Nicht genug Credits.',
        BuyResult.noCargoSpace => 'Zu wenig Frachtraum.',
        BuyResult.outOfStock => 'Nicht auf Lager.',
      };
    });
  }

  void _executeSell() {
    if (_selected == null) return;
    setState(() {
      final result = widget.player.sell(_selected!, _qty.round());
      _feedback = switch (result) {
        SellResult.success =>
          'Verkauft: ${_qty.round()} × ${_selected!.commodity.name}',
        SellResult.insufficientGoods => 'Nicht genug Ware im Lager.',
      };
    });
  }
}

// ── App Bar ──────────────────────────────────────────────────────────────────

class _StationAppBar extends StatelessWidget {
  final VoidCallback onClose;
  const _StationAppBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, topPad + 6, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.80),
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.10),
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onClose,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'RÜCKKEHR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'STATION',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryFixed,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryContainer.withValues(alpha: 0.60),
                          blurRadius: 6,
                        ),
                      ],
                    ),
              ),
              const Spacer(),
              Icon(Icons.settings_outlined, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Area ─────────────────────────────────────────────────────────────────

class _HeroArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Stack(
        children: [
          // Tactical grid pattern
          Positioned.fill(
            child: CustomPaint(painter: _TacticalGridPainter()),
          ),
          // Chromatic aberration edges
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 2,
            child: Container(
              color: AppColors.error.withValues(alpha: 0.50),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 2,
            child: Container(
              color: AppColors.primary.withValues(alpha: 0.50),
            ),
          ),
          // Name overlay (gradient from bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.surfaceContainerHighest.withValues(alpha: 0.90),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'THE SPIRE',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0.10,
                          shadows: [
                            Shadow(
                              color: AppColors.primaryContainer.withValues(alpha: 0.50),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.cell_tower, size: 12, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'HANDELS-HUB ALPHA',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.secondary,
                              letterSpacing: 0.12,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 16.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TacticalGridPainter old) => false;
}

// ── Tab Row ──────────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  final _StationTab selected;
  final ValueChanged<_StationTab> onSelect;

  const _TabRow({required this.selected, required this.onSelect});

  static const _tabs = [
    (_StationTab.markt, 'MARKT'),
    (_StationTab.bar, 'BAR'),
    (_StationTab.werft, 'WERFT'),
    (_StationTab.missionen, 'MISSIONEN'),
    (_StationTab.klonKlinik, 'KLON-KLINIK'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.50),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            final isActive = selected == tab.$1;
            return GestureDetector(
              onTap: () => onSelect(tab.$1),
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: isActive
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.50),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      )
                    : null,
                child: Text(
                  tab.$2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.outline,
                        letterSpacing: 0.12,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Market List ───────────────────────────────────────────────────────────────

class _MarketListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.30),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'WARE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outlineVariant,
                    letterSpacing: 0.12,
                  ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              'BESTAND',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outlineVariant,
                    letterSpacing: 0.08,
                    fontSize: 9,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              'KAUF/VERK',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outlineVariant,
                    letterSpacing: 0.08,
                    fontSize: 9,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              'TREND',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outlineVariant,
                    letterSpacing: 0.08,
                    fontSize: 9,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  final MarketListing listing;
  final SystemMarket market;
  final bool selected;
  final PlayerState player;
  final VoidCallback onTap;

  const _ListingRow({
    required this.listing,
    required this.market,
    required this.selected,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventM = market.eventMultiplierFor(listing.commodity.id);
    final buyP = listing.buyPrice(eventMultiplier: eventM);
    final sellP = listing.sellPrice(eventMultiplier: eventM);
    final owned = player.inventory.quantityOf(listing.commodity.id);
    final catColor = _categoryColor(listing.commodity.category);
    final (trendIcon, trendColor, trendText) = _trend(listing);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(8, 10, 0, 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? AppColors.outlineVariant.withValues(alpha: 0.30)
                  : AppColors.outlineVariant.withValues(alpha: 0.10),
            ),
            left: selected
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Category strip
            Container(
              width: 3,
              height: 22,
              color: catColor,
            ),
            const SizedBox(width: 8),
            // Commodity name
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        listing.commodity.name.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              letterSpacing: 0.04,
                              fontSize: 12,
                            ),
                      ),
                      if (listing.commodity.isIllegal) ...[
                        const SizedBox(width: 6),
                        Text(
                          'ILL',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                                fontSize: 9,
                              ),
                        ),
                      ],
                    ],
                  ),
                  if (owned > 0)
                    Text(
                      'Im Lager: $owned',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontSize: 9,
                          ),
                    ),
                ],
              ),
            ),
            // Stock
            SizedBox(
              width: 48,
              child: Text(
                listing.stock.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                      fontSize: 12,
                    ),
                textAlign: TextAlign.right,
              ),
            ),
            // Buy/Sell prices
            SizedBox(
              width: 84,
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                  children: [
                    TextSpan(
                      text: buyP.toStringAsFixed(0),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    const TextSpan(
                      text: ' / ',
                      style: TextStyle(color: AppColors.outline),
                    ),
                    TextSpan(
                      text: sellP.toStringAsFixed(0),
                      style: const TextStyle(color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ),
            // Trend
            SizedBox(
              width: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(trendIcon, size: 14, color: trendColor),
                  Text(
                    trendText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: trendColor,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(CommodityCategory cat) => switch (cat) {
        CommodityCategory.raw => AppColors.outline,
        CommodityCategory.industrial => AppColors.primary,
        CommodityCategory.luxury => AppColors.secondary,
        CommodityCategory.illegal => AppColors.error,
        CommodityCategory.research => AppColors.tertiary,
        CommodityCategory.consumable => AppColors.tertiaryContainer,
      };

  (IconData, Color, String) _trend(MarketListing l) {
    final diff = l.demandFactor - l.supplyFactor;
    if (diff > 0.15) {
      return (Icons.trending_up, AppColors.secondary, '+${(diff * 10).round()}%');
    } else if (diff < -0.15) {
      return (Icons.trending_down, AppColors.error, '${(diff * 10).round()}%');
    }
    return (Icons.trending_flat, AppColors.outline, '0%');
  }
}

// ── Trade Panel ───────────────────────────────────────────────────────────────

class _TradePanel extends StatelessWidget {
  final MarketListing listing;
  final SystemMarket market;
  final PlayerState player;
  final int qty;
  final bool isBuying;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onToggleMode;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  const _TradePanel({
    required this.listing,
    required this.market,
    required this.player,
    required this.qty,
    required this.isBuying,
    required this.onQtyChanged,
    required this.onToggleMode,
    required this.onBuy,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final eventM = market.eventMultiplierFor(listing.commodity.id);
    final unitPrice = isBuying
        ? listing.buyPrice(eventMultiplier: eventM)
        : listing.sellPrice(eventMultiplier: eventM);
    final total = unitPrice * qty;
    final maxBuy = listing.stock
        .clamp(0, (player.credits / unitPrice).floor())
        .toDouble();
    final maxSell =
        player.inventory.quantityOf(listing.commodity.id).toDouble();
    final maxQty = isBuying ? maxBuy : maxSell;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.80),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ZIEL: ${listing.commodity.name.toUpperCase()}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        'Total: ${total.toStringAsFixed(0)} CR',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${unitPrice.toStringAsFixed(0)} CR',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 20,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                  ),
                  Text(
                    'PRO EINHEIT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Slider
          if (maxQty > 0) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.outlineVariant,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.15),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                min: 1,
                max: maxQty,
                value: qty.clamp(1, maxQty).toDouble(),
                onChanged: maxQty >= 1 ? onQtyChanged : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.outline,
                        )),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.50),
                    ),
                  ),
                  child: Text(
                    '$qty EINHEITEN',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ),
                Text(
                  'MAX',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.outline,
                      ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isBuying
                    ? 'Nicht auf Lager oder keine Credits.'
                    : 'Keine Ware im Lager.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),

          const SizedBox(height: 12),

          // Buy/Sell buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'VERKAUFEN',
                  icon: Icons.sell_outlined,
                  active: !isBuying,
                  isAccent: false,
                  onTap: !isBuying && maxSell > 0 ? onSell : onToggleMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'KAUFEN',
                  icon: Icons.shopping_cart_checkout,
                  active: isBuying,
                  isAccent: true,
                  onTap: isBuying && maxBuy > 0 ? onBuy : onToggleMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isAccent;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.isAccent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAccent ? AppColors.primary : AppColors.outline;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active && isAccent
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceContainerLowest,
          border: Border.all(color: color),
          boxShadow: active && isAccent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    letterSpacing: 0.12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feedback ──────────────────────────────────────────────────────────────────

class _Feedback extends StatelessWidget {
  final String message;
  const _Feedback({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
            ),
      ),
    );
  }
}

// ── Status Bar ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final PlayerState player;
  const _StatusBar({required this.player});

  @override
  Widget build(BuildContext context) {
    final used = player.inventory.usedCapacity;
    final max = player.inventory.maxCapacity;
    final fillRatio = (used / max).clamp(0.0, 1.0);
    final filledSegments = (fillRatio * 10).round();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.30),
          ),
        ),
      ),
      child: Row(
        children: [
          // Credits
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 12, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    'CREDITS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                ],
              ),
              Text(
                '${player.credits.toStringAsFixed(0)} CR',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryFixed,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryFixed.withValues(alpha: 0.50),
                          blurRadius: 2,
                        ),
                      ],
                    ),
              ),
            ],
          ),
          const Spacer(),
          // Cargo bar (segmented 10 blocks)
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          'FRACHT',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.outline,
                                  ),
                        ),
                      ],
                    ),
                    Text(
                      '${used.toStringAsFixed(0)}/${max.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryFixed,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(10, (i) {
                    final filled = i < filledSegments;
                    return Expanded(
                      child: Container(
                        height: 10,
                        margin: i < 9
                            ? const EdgeInsets.only(right: 2)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.secondary
                              : AppColors.surfaceContainerLowest,
                          border: Border.all(
                            color: filled
                                ? AppColors.secondary.withValues(alpha: 0.50)
                                : AppColors.outlineVariant,
                            width: 1,
                          ),
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondaryContainer
                                        .withValues(alpha: 0.50),
                                    blurRadius: 4,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Placeholder ───────────────────────────────────────────────────────────

class _TabPlaceholder extends StatelessWidget {
  final _StationTab tab;
  const _TabPlaceholder({required this.tab});

  @override
  Widget build(BuildContext context) {
    final label = switch (tab) {
      _StationTab.bar => 'BAR',
      _StationTab.werft => 'WERFT',
      _StationTab.missionen => 'MISSIONEN',
      _StationTab.klonKlinik => 'KLON-KLINIK',
      _StationTab.markt => 'MARKT',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '$label — bald verfügbar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.outline,
              ),
        ),
      ),
    );
  }
}
