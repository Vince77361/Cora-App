/// 오퍼가 화면에 보이는 상태. 서버가 사장님과 크리에이터 각자에게 맞게 풀어서 보낸다
/// (예: 거절은 되돌릴 수 있는 30초 동안 사장님에게 `waiting`으로 보인다).
enum OfferView { waiting, accepted, declined, expired, cancelled }
