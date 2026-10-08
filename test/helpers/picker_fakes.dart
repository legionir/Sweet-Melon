import 'package:image_picker/image_picker.dart';

/// Fake picker for the native boundary. Every picker call returns what the user
/// selected: nothing for single pickers, [selection] for the multi picker.
/// `noSuchMethod` forwards any other member, so the fake does not depend on the
/// exact parameter lists of the image_picker version.
class CancellingPicker implements ImagePicker {
  int pickCalls = 0;
  final List<XFile> selection;

  CancellingPicker({this.selection = const []});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #pickMultiImage) {
      pickCalls++;
      return Future<List<XFile>>.value(selection);
    }
    if (name == #pickImage || name == #pickVideo) {
      pickCalls++;
      return Future<XFile?>.value(null);
    }
    return super.noSuchMethod(invocation);
  }
}

