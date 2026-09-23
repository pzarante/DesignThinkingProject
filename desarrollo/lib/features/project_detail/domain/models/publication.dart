/// Publicacion compartida dentro del muro de un proyecto.
class Publication {
  const Publication({
    required this.id,
    required this.projectId,
    required this.authorName,
    required this.title,
    required this.content,
    this.imageUrl,
    this.createdAt,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.viewerReacted = false,
    this.comments = const [],
  });

  final String id;
  final String projectId;
  final String authorName;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;
  final int reactionCount;
  final int commentCount;
  final bool viewerReacted;
  final List<String> comments;

  Publication copyWith({
    String? title,
    String? content,
    String? imageUrl,
    int? reactionCount,
    int? commentCount,
    bool? viewerReacted,
    List<String>? comments,
  }) {
    return Publication(
      id: id,
      projectId: projectId,
      authorName: authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      viewerReacted: viewerReacted ?? this.viewerReacted,
      comments: comments ?? this.comments,
    );
  }
}
