interface RequestLike {
  headers: Record<string, string | string[] | undefined>;
  socket: { remoteAddress?: string };
}

// 소켓 핸드셰이크의 요청 IP. HTTP(express의 trust proxy = TRUST_PROXY_HOPS)와 같은 규칙이다:
// 0이면 X-Forwarded-For를 믿지 않고 연결 주소를 쓴다(누구나 헤더로 IP를 속일 수 있다). n이면 연결 주소에서 n칸 안쪽까지의 프록시를 믿는다.
export function clientIpOf(request: RequestLike, trustedHops: number): string {
  const remote = request.socket.remoteAddress ?? 'unknown';
  if (trustedHops <= 0) return remote;
  const header = request.headers['x-forwarded-for'];
  const forwarded = (Array.isArray(header) ? header.join(',') : (header ?? ''))
    .split(',')
    .map((part) => part.trim())
    .filter((part) => part !== '');
  // 왼쪽이 클라이언트에 가깝다. 맨 오른쪽이 우리에게 직접 붙은 연결 주소다.
  const chain = [...forwarded, remote];
  return chain[Math.max(chain.length - 1 - trustedHops, 0)];
}
