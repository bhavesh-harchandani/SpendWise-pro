import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PocketTrackerApp());
}

class PocketTrackerApp extends StatelessWidget {
  const PocketTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpendWise Pro',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const ExpenseTrackerDashboard(),
    );
  }
}

class ExpenseTrackerDashboard extends StatefulWidget {
  const ExpenseTrackerDashboard({super.key});

  @override
  State<ExpenseTrackerDashboard> createState() => _ExpenseTrackerDashboardState();
}

class _ExpenseTrackerDashboardState extends State<ExpenseTrackerDashboard> {
  List<Map<String, dynamic>> _transactions = [];
  String _selectedFilter = 'All';

  // Multi-Selection State
  bool _isSelectionMode = false;
  final List<String> _selectedIds = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _formIsExpense = true;

  @override
  void initState() {
    super.initState();
    _loadTransactionsFromDatabase();
  }

  Future<void> _loadTransactionsFromDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final String? txString = prefs.getString('saved_tx');
    if (txString != null) {
      final List<dynamic> decodedList = jsonDecode(txString);
      setState(() {
        _transactions = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  Future<void> _saveTransactionsToDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_transactions);
    await prefs.setString('saved_tx', encodedData);
  }

  int get totalIncome => _transactions.where((tx) => !tx['isExpense']).fold(0, (sum, tx) => sum + (tx['amount'] as int));
  int get totalExpense => _transactions.where((tx) => tx['isExpense']).fold(0, (sum, tx) => sum + (tx['amount'] as int));

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'Income') {
      return _transactions.where((tx) => !tx['isExpense']).toList();
    } else if (_selectedFilter == 'Expense') {
      return _transactions.where((tx) => tx['isExpense']).toList();
    }
    return _transactions;
  }

  // Handle item tap or long press for multi-selection
  void _handleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // Multi-delete functionality
  void _deleteSelectedTransactions() {
    setState(() {
      _transactions.removeWhere((tx) => _selectedIds.contains(tx['id']));
      _selectedIds.clear();
      _isSelectionMode = false;
    });
    _saveTransactionsToDatabase();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected transactions deleted successfully.')),
    );
  }

  void _showAddTransactionForm(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Transaction Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Expense')),
                          selected: _formIsExpense == true,
                          selectedColor: const Color(0xFFFEF2F2),
                          checkmarkColor: Colors.red,
                          onSelected: (val) => setModalState(() => _formIsExpense = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Income')),
                          selected: _formIsExpense == false,
                          selectedColor: const Color(0xFFECFDF5),
                          checkmarkColor: Colors.green,
                          onSelected: (val) => setModalState(() => _formIsExpense = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
                        setState(() {
                          _transactions.insert(0, {
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'title': _titleController.text,
                            'category': _formIsExpense ? 'Expense' : 'Income',
                            'amount': int.parse(_amountController.text),
                            'isExpense': _formIsExpense,
                            'date': 'Today',
                          });
                        });
                        _saveTransactionsToDatabase();
                        _titleController.clear();
                        _amountController.clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save Transaction', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Dynamic Title: Selection mode me select kiye hue items ka count dikhega
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} Selected' : 'SpendWise Pro',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _isSelectionMode ? Colors.red[900] : const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.white),
              onPressed: _deleteSelectedTransactions,
            )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: _isSelectionMode ? Colors.red[900] : const Color(0xFF0F172A),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricSection('TOTAL CASH-IN', '₹$totalIncome', Colors.tealAccent),
                Container(width: 1, height: 45, color: Colors.white24),
                _buildMetricSection('TOTAL CASH-OUT', '₹$totalExpense', Colors.pinkAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Income', 'Expense'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
                    onSelected: (val) {
                      setState(() { _selectedFilter = filter; });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions found!'))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      final isExpense = tx['isExpense'] as bool;
                      final txId = tx['id'] ?? index.toString();
                      final isSelected = _selectedIds.contains(txId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: GestureDetector(
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedIds.add(txId);
                              });
                            }
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              _handleItemSelection(txId);
                            }
                          },
                          child: Card(
                            elevation: isSelected ? 4 : 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: isSelected 
                                  ? const BorderSide(color: Colors.red, width: 2) 
                                  : BorderSide.none,
                            ),
                            color: isSelected ? Colors.red[50] : Colors.white,
                            child: ListTile(
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      activeColor: Colors.red[700],
                                      onChanged: (val) => _handleItemSelection(txId),
                                    )
                                  : CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isExpense ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                      child: Icon(
                                        isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                                        color: isExpense ? Colors.red[600] : Colors.green[600],
                                      ),
                                    ),
                              title: Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${tx['category']} • ${tx['date']}', style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                '${isExpense ? "-" : "+"}₹${tx['amount']}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isExpense ? Colors.red[700] : Colors.green[700]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null // Selection mode me naya item add karne wala button chhip jayega
          : FloatingActionButton(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _showAddTransactionForm(context),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
    );
  }

  Widget _buildMetricSection(String label, String value, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}