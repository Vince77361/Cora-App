export interface Bank {
  // 금융결제원 은행 코드(세 자리).
  code: string;
  // 고르는 목록에 쓰는 짧은 이름.
  name: string;
  // 지급 계좌 화면(E7)에 보이는 이름.
  fullName: string;
}

// 코드는 금융결제원 은행 코드표와 대조했다. 031은 대구은행이 2025년에 iM뱅크로 이름을 바꾼 코드다(코드는 그대로).
export const BANKS: readonly Bank[] = [
  { code: '004', name: '국민', fullName: '국민은행' },
  { code: '088', name: '신한', fullName: '신한은행' },
  { code: '020', name: '우리', fullName: '우리은행' },
  { code: '081', name: '하나', fullName: '하나은행' },
  { code: '011', name: '농협', fullName: 'NH농협은행' },
  { code: '003', name: '기업', fullName: 'IBK기업은행' },
  { code: '090', name: '카카오뱅크', fullName: '카카오뱅크' },
  { code: '092', name: '토스뱅크', fullName: '토스뱅크' },
  { code: '089', name: '케이뱅크', fullName: '케이뱅크' },
  { code: '045', name: '새마을금고', fullName: '새마을금고' },
  { code: '071', name: '우체국', fullName: '우체국' },
  { code: '023', name: 'SC제일', fullName: 'SC제일은행' },
  { code: '032', name: '부산', fullName: '부산은행' },
  { code: '031', name: '대구', fullName: '대구은행' },
  { code: '034', name: '광주', fullName: '광주은행' },
  { code: '037', name: '전북', fullName: '전북은행' },
  { code: '039', name: '경남', fullName: '경남은행' },
  { code: '035', name: '제주', fullName: '제주은행' },
  { code: '007', name: '수협', fullName: '수협은행' },
  { code: '048', name: '신협', fullName: '신협' },
];

export const BANK_CODES: readonly string[] = BANKS.map((b) => b.code);

export function findBank(code: string): Bank | undefined {
  return BANKS.find((b) => b.code === code);
}
