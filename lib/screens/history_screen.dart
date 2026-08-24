import 'package:flutter/material.dart';
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

  String _formatCnpj(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.'
        '${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-'
        '${cnpj.substring(12)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        title: const Text('Histórico',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF161b22),
        foregroundColor: const Color(0xFFe6edf3),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Divider(height: 1, color: Color(0xFF30363d)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2f81f7)))
          : Column(
              children: [
                Expanded(
                  child: _history.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma consulta encontrada',
                            style: TextStyle(
                                color: Color(0xFF8b949e), fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final empresa = _history[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161b22),
                                border: Border.all(
                                    color: const Color(0xFF30363d)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  empresa.razaoSocial ?? 'Sem nome',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFe6edf3),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatCnpj(empresa.cnpj),
                                  style: const TextStyle(
                                    color: Color(0xFF58a6ff),
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () =>
                                    Navigator.pop(context, empresa.cnpj),
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF21262d),
                          foregroundColor: const Color(0xFFf85149),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFF30363d)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          await _storage.clearHistory();
                          _load();
                        },
                        child: const Text('LIMPAR HISTÓRICO',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
