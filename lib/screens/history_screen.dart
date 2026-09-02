import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/empresa.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = StorageService();
  List<Empresa> _history = [];
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
    final list = await _storage.loadHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _loading = false;
      });
    }
  }

  Future<void> _removeItem(Empresa empresa) async {
    _history.removeWhere((e) => e.cnpj == empresa.cnpj);
    await _storage.saveHistory(_history);
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
        title: const Text('Limpar Histórico',
            style: TextStyle(color: _textPrimary)),
        content: const Text(
          'Tem certeza que deseja limpar todo o histórico?',
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
      await _storage.clearHistory();
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
            const Text('Histórico',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: _textPrimary)),
            if (!_loading)
              Text(
                _history.isEmpty
                    ? 'Nenhum item'
                    : '${_history.length} ${_history.length == 1 ? 'item' : 'itens'}',
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
          : Column(
              children: [
                Expanded(
                  child: _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.history,
                                  size: 64, color: _border),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma consulta encontrada',
                                style: TextStyle(
                                    color: _textSecondary, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Suas consultas de CNPJ aparecerão aqui',
                                style: TextStyle(
                                    color: _textSecondary, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final empresa = _history[index];
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
                                onTap: () =>
                                    Navigator.pop(context, empresa.cnpj),
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
                                              empresa.razaoSocial ??
                                                  'Sem nome',
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
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
                if (_history.isNotEmpty)
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
                        label: const Text('LIMPAR HISTÓRICO',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
