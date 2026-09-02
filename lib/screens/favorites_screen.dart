import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/empresa.dart';
import '../services/storage_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _storage = StorageService();
  List<Empresa> _favorites = [];
  bool _loading = true;

  static const _primary = Color(0xFF1A4C89);
  static const _surface = Color(0xFF0F1724);
  static const _card = Color(0xFF162033);
  static const _border = Color(0xFF1E3A5F);
  static const _textPrimary = Color(0xFFE2E8F0);
  static const _textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _storage.loadFavorites();
    if (mounted) {
      setState(() {
        _favorites = list;
        _loading = false;
      });
    }
  }

  Future<void> _removeItem(Empresa empresa) async {
    _favorites.removeWhere((e) => e.cnpj == empresa.cnpj);
    await _storage.saveFavorites(_favorites);
    if (mounted) setState(() {});
  }

  Future<void> _copyCnpj(String cnpj) async {
    await Clipboard.setData(ClipboardData(text: cnpj));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CNPJ $_cnpj copiado!'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _confirmClear() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Limpar Favoritos',
            style: TextStyle(color: _textPrimary)),
        content: const Text(
          'Tem certeza que deseja remover todos os favoritos?',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar', style: TextStyle(color: Color(0xFFF85149))),
          ),
        ],
      ),
    );
    if (result == true) {
      await _storage.clearFavorites();
      _load();
    }
  }

  String _formatCnpj(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.'
        '${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-'
        '${cnpj.substring(12)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Favoritos',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _textPrimary)),
            if (!_loading)
              Text(
                _favorites.isEmpty
                    ? 'Nenhum item'
                    : '${_favorites.length} ${_favorites.length == 1 ? 'item' : 'itens'}',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
          ],
        ),
        backgroundColor: _surface,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.favorite_border,
                          size: 64, color: _border),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum favorito encontrado',
                        style: TextStyle(color: _textSecondary, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Adicione empresas aos favoritos para encontrá-las facilmente',
                        style: TextStyle(color: _textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final empresa = _favorites[index];
                          return Dismissible(
                            key: Key(empresa.cnpj),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF85149),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 28),
                            ),
                            onDismissed: (_) => _removeItem(empresa),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context, empresa.cnpj),
                              onLongPress: () => _copyCnpj(empresa.cnpj),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _card,
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            empresa.razaoSocial ?? 'Sem nome',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCnpj(empresa.cnpj),
                                            style: const TextStyle(
                                              color: _primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: _textSecondary, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _card,
                            foregroundColor: const Color(0xFFF85149),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: _border),
                            elevation: 0,
                          ),
                          onPressed: _confirmClear,
                          label: const Text('LIMPAR FAVORITOS',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
