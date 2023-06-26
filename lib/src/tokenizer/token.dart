import 'package:meta/meta.dart';

/// An immutable data container for a type [T] representing a canonical value in a [Vocabulary]<[T]>
/// True canonical values should be used for [T] whenever possible.
@immutable
class Token<T> {
  /// The content of this token. Prefer canonicalized builtin types whenever possible.
  final T content;

  @override
  String toString() => content.toString();

  @override
  int get hashCode => content.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Token<T> && other.content == content;

  /// Create a new instance.
  const Token(this.content);
}
