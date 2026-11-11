/// 앱에서 쓰는 역할. 가게 사장님, 브랜드 담당자, 크리에이터.
///
/// 서버의 역할 이름(STORE, BRAND, CREATOR)과 일대일이다. 서버 타입은 data 계층 안에서만 쓰고
/// 여기로 옮겨 온다.
enum UserRole { store, brand, creator }
