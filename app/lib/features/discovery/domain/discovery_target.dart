/// 결정을 받는 대상의 종류. 브랜드는 크리에이터를, 크리에이터는 캠페인과 가게를 본다.
enum DiscoveryTargetKind { creator, campaign, store }

/// 관심·넘김·보류를 보내는 대상 하나.
class DiscoveryTarget {
  const DiscoveryTarget(this.kind, this.id);

  const DiscoveryTarget.creator(String id)
    : this(DiscoveryTargetKind.creator, id);
  const DiscoveryTarget.campaign(String id)
    : this(DiscoveryTargetKind.campaign, id);
  const DiscoveryTarget.store(String id) : this(DiscoveryTargetKind.store, id);

  final DiscoveryTargetKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is DiscoveryTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}
