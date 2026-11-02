import { atom, useRecoilValue } from 'recoil';
import { mockAgent, mockChapters, mockPenalCodes, mockRanks } from '../data/mock';
import { isBrowser } from '../utils/nui';

export const globalScope = globalThis;

export const atomRegistry = (globalScope.__sagaRecoilAtoms__ ??= {});

export function sharedAtom(e, t): any {
  if (!atomRegistry[e]) {
    atomRegistry[e] = atom({
      key: e,
      default: t,
    });
  }
  return atomRegistry[e];
}

export const penalCodeListAtom = sharedAtom('penalCodeList', isBrowser() ? mockPenalCodes : []);

export const chapterListAtom = sharedAtom('chapterList', isBrowser() ? mockChapters : []);

export const agentAtom = sharedAtom('agentAtom', isBrowser() ? mockAgent : null);

export const ranksAgentsAtom = sharedAtom('ranksAgentsAtom', isBrowser() ? mockRanks : []);

export const usePermissions = () => {
  const e = useRecoilValue<any>(agentAtom);
  const t = useRecoilValue<any>(ranksAgentsAtom);
  return {
    haveRankPerms: (r, o?) => {
      if (!e) {
        return false;
      }
      const s = t.find((item) => item.grade === e.rank_id);
      return s
        ? o === e.citizen.citizenid || s.isBoss
          ? true
          : s.permissions.some((permission) => r.includes(permission))
        : false;
    },
  };
};
