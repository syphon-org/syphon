import 'dart:async';

class LockController {
  LockController();

  late bool _isConfirmed;
  late int _maxLength;
  late Future<bool> Function(String input) _onVerifyInput;

  final List<String> _currentInputs = [];

  late StreamController<bool> loadingController;
  late StreamController<bool> verifyController;
  late StreamController<String> inputController;
  late StreamController<bool> confirmedController;

  /// Get latest input text stream.
  Stream<bool> get loading => loadingController.stream;

  Stream<String> get currentInput => inputController.stream;

  /// Get verify result stream.
  Stream<bool> get verifyInput => verifyController.stream;

  /// Get confirmed result stream.
  Stream<bool> get confirmed => confirmedController.stream;

  String _firstInput = '';

  String get confirmedInput => _firstInput;

  /// Add some text at the end and stream it.
  void addCharacter(String input) {
    _currentInputs.add(input);
    inputController.add(_currentInputs.join());

    if (_currentInputs.length >= _maxLength) {
      return;
    }
  }

  /// Remove the trailing characters and stream it.
  void removeCharacter() {
    if (_currentInputs.isNotEmpty) {
      _currentInputs.removeLast();
      inputController.add(_currentInputs.join());
    }
  }

  /// Erase all current input.
  void clear() {
    if (_currentInputs.isNotEmpty) {
      _currentInputs.clear();
      if (inputController.isClosed == false) {
        inputController.add('');
      }
    }
  }

  void setConfirmed() {
    _firstInput = _currentInputs.join();
    confirmedController.add(true);
  }

  void unsetConfirmed() {
    _firstInput = '';
    confirmedController.add(false);
    clear();
  }

  /// Verify that the input is correct.
  Future verify() async {
    loadingController.add(true);

    final inputText = _currentInputs.join();

    if (!_isConfirmed) {
      final verified = await _onVerifyInput(inputText);

      if (!verified) {
        loadingController.add(false);
      }

      return verifyController.add(verified);
    } else {
      if (_firstInput.isEmpty) {
        setConfirmed();
        clear();
        return;
      }

      if (inputText == _firstInput) {
        verifyController.add(true);
      } else {
        verifyController.add(false);
      }

      loadingController.add(false);
    }
  }

  /// Create each stream.
  void initialize({
    int maxLength = 9, // DEFAULT MAX LENGTH
    bool isConfirmed = false,
    required Future<bool> Function(String input) onVerifyInput,
  }) {
    loadingController = StreamController.broadcast();
    inputController = StreamController.broadcast();
    verifyController = StreamController.broadcast();
    confirmedController = StreamController.broadcast();

    _onVerifyInput = onVerifyInput;
    _isConfirmed = isConfirmed;
    _maxLength = maxLength;
  }

  /// Close all streams.
  void dispose() {
    inputController.close();
    verifyController.close();
    confirmedController.close();
  }
}
