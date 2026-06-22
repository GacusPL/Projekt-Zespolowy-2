import 'package:flutter/material.dart';

/// Utrzymuje stan dziecka przy życiu, gdy znika z viewportu (np. zakładki
/// `TabBarView`). Bez tego przełączenie zakładki niszczy stan/BLoC zakładki —
/// m.in. przerywałoby trwający stream czatu.
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
