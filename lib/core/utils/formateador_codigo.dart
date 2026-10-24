import 'package:flutter/services.dart';

import 'validadores.dart';

// convierte el codigo a mayusculas, descarta lo que no sea letra o numero y corta en 6
class FormateadorCodigo extends TextInputFormatter {
  static final _noPermitidos = RegExp('[^A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var texto = newValue.text.toUpperCase().replaceAll(_noPermitidos, '');
    if (texto.length > Validadores.largoCodigo) {
      texto = texto.substring(0, Validadores.largoCodigo);
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
