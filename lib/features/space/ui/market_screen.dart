import 'package:flutter/material.dart';
import '../../../core/domain/commodity.dart';
import '../../../core/domain/market.dart';
import '../../../core/domain/player_state.dart';

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

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  MarketListing? _selected;
  int _qty = 1;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF050A14),
      child: Column(
        children: [
          _Header(
            credits: widget.player.credits,
            cargoUsed: widget.player.inventory.usedCapacity,
            cargoMax: widget.player.inventory.maxCapacity,
            onClose: widget.onClose,
            activeEvents: widget.market.activeEvents,
          ),
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFF69FF47),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: const [Tab(text: 'KAUFEN'), Tab(text: 'VERKAUFEN')],
          ),
          if (_feedback != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: const Color(0xFF1A2A1A),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Text(_feedback!, style: const TextStyle(color: Color(0xFF69FF47), fontSize: 12)),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ListingTable(
                  listings: widget.market.listings.where((l) => l.stock > 0).toList(),
                  market: widget.market,
                  mode: _TradeMode.buy,
                  selected: _selected,
                  onSelect: (l) => setState(() { _selected = l; _qty = 1; }),
                ),
                _ListingTable(
                  listings: widget.market.listings,
                  market: widget.market,
                  mode: _TradeMode.sell,
                  selected: _selected,
                  onSelect: (l) => setState(() { _selected = l; _qty = 1; }),
                  playerInventory: widget.player.inventory,
                ),
              ],
            ),
          ),
          if (_selected != null) _TradePanel(
            listing: _selected!,
            market: widget.market,
            player: widget.player,
            mode: _tabs.index == 0 ? _TradeMode.buy : _TradeMode.sell,
            qty: _qty,
            onQtyChanged: (q) => setState(() => _qty = q),
            onConfirm: _executeTrade,
          ),
        ],
      ),
    );
  }

  void _executeTrade() {
    if (_selected == null) return;
    setState(() {
      if (_tabs.index == 0) {
        final result = widget.player.buy(_selected!, _qty);
        _feedback = switch (result) {
          BuyResult.success => 'Gekauft: $_qty × ${_selected!.commodity.name}',
          BuyResult.insufficientCredits => 'Nicht genug Credits.',
          BuyResult.noCargoSpace => 'Zu wenig Frachtraum.',
          BuyResult.outOfStock => 'Nicht auf Lager.',
        };
      } else {
        final result = widget.player.sell(_selected!, _qty);
        _feedback = switch (result) {
          SellResult.success => 'Verkauft: $_qty × ${_selected!.commodity.name}',
          SellResult.insufficientGoods => 'Nicht genug Ware im Lager.',
        };
      }
    });
  }
}

enum _TradeMode { buy, sell }

class _Header extends StatelessWidget {
  final double credits;
  final double cargoUsed;
  final double cargoMax;
  final VoidCallback onClose;
  final List<MarketEvent> activeEvents;

  const _Header({
    required this.credits,
    required this.cargoUsed,
    required this.cargoMax,
    required this.onClose,
    required this.activeEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF080820),
        border: Border(bottom: BorderSide(color: Color(0xFF1A237E))),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Color(0xFF4FC3F7), size: 20),
          const SizedBox(width: 10),
          const Text('MARKT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const Spacer(),
          if (activeEvents.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF4A0000), borderRadius: BorderRadius.circular(4)),
              child: Text('⚡ ${activeEvents.first.label}', style: const TextStyle(color: Color(0xFFFF5252), fontSize: 11)),
            ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${credits.toStringAsFixed(0)} ₵', style: const TextStyle(color: Color(0xFFFFD740), fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Fracht: ${cargoUsed.toStringAsFixed(1)}/${cargoMax.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: onClose),
        ],
      ),
    );
  }
}

class _ListingTable extends StatelessWidget {
  final List<MarketListing> listings;
  final SystemMarket market;
  final _TradeMode mode;
  final MarketListing? selected;
  final ValueChanged<MarketListing> onSelect;
  final Inventory? playerInventory;

  const _ListingTable({
    required this.listings,
    required this.market,
    required this.mode,
    required this.selected,
    required this.onSelect,
    this.playerInventory,
  });

  @override
  Widget build(BuildContext context) {
    final displayList = mode == _TradeMode.sell
        ? listings.where((l) => (playerInventory?.quantityOf(l.commodity.id) ?? 0) > 0).toList()
        : listings;

    if (displayList.isEmpty) {
      return const Center(child: Text('Keine Waren verfügbar.', style: TextStyle(color: Colors.white38)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: displayList.length,
      separatorBuilder: (context, index) => const Divider(color: Color(0xFF1A2A3A), height: 1),
      itemBuilder: (_, i) {
        final l = displayList[i];
        final isSelected = selected?.commodity.id == l.commodity.id;
        final eventM = market.eventMultiplierFor(l.commodity.id);
        final price = mode == _TradeMode.buy ? l.buyPrice(eventMultiplier: eventM) : l.sellPrice(eventMultiplier: eventM);
        final ownedQty = playerInventory?.quantityOf(l.commodity.id) ?? 0;

        return InkWell(
          onTap: () => onSelect(l),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isSelected ? const Color(0xFF0D2040) : Colors.transparent,
            child: Row(
              children: [
                _CategoryDot(l.commodity.category),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(l.commodity.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          if (l.commodity.isIllegal) const SizedBox(width: 6),
                          if (l.commodity.isIllegal)
                            const Text('ILLEGAL', style: TextStyle(color: Color(0xFFFF5252), fontSize: 9, letterSpacing: 1)),
                        ],
                      ),
                      if (ownedQty > 0)
                        Text('Im Lager: $ownedQty', style: const TextStyle(color: Color(0xFF69FF47), fontSize: 10)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${price.toStringAsFixed(0)} ₵', style: TextStyle(
                      color: mode == _TradeMode.buy ? const Color(0xFFFFD740) : const Color(0xFF69FF47),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )),
                    Text('Lager: ${l.stock}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final CommodityCategory category;
  const _CategoryDot(this.category);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (category) {
          CommodityCategory.raw => const Color(0xFFBCAAA4),
          CommodityCategory.industrial => const Color(0xFF90A4AE),
          CommodityCategory.luxury => const Color(0xFFFFD740),
          CommodityCategory.illegal => const Color(0xFFFF5252),
          CommodityCategory.research => const Color(0xFFCE93D8),
          CommodityCategory.consumable => const Color(0xFF81C784),
        },
      ),
    );
  }
}

class _TradePanel extends StatelessWidget {
  final MarketListing listing;
  final SystemMarket market;
  final PlayerState player;
  final _TradeMode mode;
  final int qty;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onConfirm;

  const _TradePanel({
    required this.listing,
    required this.market,
    required this.player,
    required this.mode,
    required this.qty,
    required this.onQtyChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final eventM = market.eventMultiplierFor(listing.commodity.id);
    final unitPrice = mode == _TradeMode.buy
        ? listing.buyPrice(eventMultiplier: eventM)
        : listing.sellPrice(eventMultiplier: eventM);
    final total = unitPrice * qty;
    final maxQty = mode == _TradeMode.buy
        ? listing.stock.clamp(0, (player.credits / unitPrice).floor())
        : player.inventory.quantityOf(listing.commodity.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF080820),
        border: Border(top: BorderSide(color: Color(0xFF1A237E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.commodity.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${unitPrice.toStringAsFixed(0)} ₵/Stk — Gesamt: ${total.toStringAsFixed(0)} ₵',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          _QtyButton('-', () { if (qty > 1) onQtyChanged(qty - 1); }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _QtyButton('+', () { if (qty < maxQty) onQtyChanged(qty + 1); }),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mode == _TradeMode.buy ? const Color(0xFF1565C0) : const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            onPressed: maxQty > 0 ? onConfirm : null,
            child: Text(mode == _TradeMode.buy ? 'KAUFEN' : 'VERKAUFEN'),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _QtyButton(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1A3A5C)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
