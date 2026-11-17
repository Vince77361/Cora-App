import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { securityLog } from '../common/logging/security-log';
import { runWithRequestContext } from '../common/request-context/request-context';
import { OpsError } from './ops-error';
import { ParsedOpsCommand, parseOpsArgs, usageLines } from './ops-args';
import { OpsResult, OpsService } from './ops.service';

export interface OpsRunResult {
  // 0 성공, 1 거절·실패·경고(커밋된 뒤의 단계에서 문제가 난 경우 포함).
  exitCode: 0 | 1;
  output: string[];
}

// 명령줄 인자를 읽어 OpsService의 명령을 실행하고 출력할 줄을 만든다. 프로세스를 끝내지 않으므로 테스트가 그대로 부른다.
@Injectable()
export class OpsRunner {
  constructor(private readonly service: OpsService) {}

  async run(argv: string[]): Promise<OpsRunResult> {
    const parsed = parseOpsArgs(argv);
    if (!parsed.ok) {
      return { exitCode: 1, output: [parsed.error, '', ...usageLines()] };
    }
    return this.execute(parsed.command);
  }

  // 명령 한 번이 하나의 요청처럼 로그에 묶이도록 요청 ID(ops:<명령>:<무작위>)를 정하고 보안 로그를 남긴다.
  // --operator와 --reason의 자유 입력은 로그에 넣지 않는다(감사 기록은 ops_audit_logs가 맡는다).
  execute(command: ParsedOpsCommand): Promise<OpsRunResult> {
    const name = command.spec.name;
    return runWithRequestContext(
      { requestId: `ops:${name}:${randomUUID()}` },
      async (): Promise<OpsRunResult> => {
        const v = command.values;
        const target = [
          v.collaboration,
          v.payout,
          v.refund,
          v.payment,
          v.report,
          v.conversation,
        ].find((id): id is string => typeof id === 'string');
        const log = (result: 'ALLOWED' | 'DENIED' | 'FAILED') =>
          securityLog('OPS_COMMAND', { target, result, reason: name });
        let result: OpsResult;
        try {
          result = await this.dispatch(command);
        } catch (error) {
          // 규칙이 거절한 명령(OpsError)과 예상 못 한 실패를 구별한다.
          if (error instanceof OpsError) {
            log('DENIED');
            return { exitCode: 1, output: [error.message] };
          }
          log('FAILED');
          throw error;
        }
        const exitCode: 0 | 1 = result.warnings.length > 0 ? 1 : 0;
        log(exitCode === 0 ? 'ALLOWED' : 'FAILED');
        return {
          exitCode,
          output: [
            ...result.lines,
            ...result.warnings.map((w) => `경고: ${w}`),
            ...(result.warnings.length > 0
              ? [
                  '돈의 상태는 이미 커밋됐어요. show로 확인하고 필요한 retry-* 명령으로 이어 가세요.',
                ]
              : []),
          ],
        };
      },
    );
  }

  private dispatch(command: ParsedOpsCommand): Promise<OpsResult> {
    const actor = { operator: command.operator, reason: command.reason };
    const v = command.values;
    switch (command.spec.name) {
      case 'halt':
        return this.service.halt(v.collaboration as string, actor);
      case 'resume':
        return this.service.resume(v.collaboration as string, actor);
      case 'resume-settlement':
        return this.service.resumeSettlement(
          v.collaboration as string,
          v.views as number,
          actor,
        );
      case 'force-refund':
        return this.service.forceRefund(v.collaboration as string, actor);
      case 'force-payout':
        return this.service.forcePayout(
          v.collaboration as string,
          v.amount as number,
          actor,
        );
      case 'retry-payout':
        return this.service.retryPayout(v.payout as string, actor);
      case 'retry-refund':
        return this.service.retryRefund(v.refund as string, actor);
      case 'refund-payment':
        return this.service.refundPayment(v.payment as string, actor);
      case 'confirm-evidence':
        return this.service.confirmEvidence(v.collaboration as string, actor);
      case 'resolve-dispute':
        return this.service.resolveDispute(
          v.collaboration as string,
          v.views as number | undefined,
          actor,
        );
      case 'resolve-report':
        return this.service.resolveReport(v.report as string, actor);
      case 'show-conversation':
        return this.service.showConversation(
          v.conversation as string,
          v.limit as number | undefined,
          actor,
        );
      case 'show':
        return this.service.show(v.collaboration as string);
      default:
        return Promise.reject(
          new OpsError(`모르는 명령이에요: ${command.spec.name}`),
        );
    }
  }
}
