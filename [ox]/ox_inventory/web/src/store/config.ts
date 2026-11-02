export const Config: {
  layout: 'classic' | 'loadout';
  disableUseInBackpack: boolean;
  backpackItems: string[];
  allowItemRename: boolean;
  allowBackpackRename: boolean;
  loadoutSideTilt: boolean;
  performanceProfiling: boolean;
} = {
  layout: 'classic',
  disableUseInBackpack: false,
  backpackItems: [],
  allowItemRename: true,
  allowBackpackRename: true,
  loadoutSideTilt: true,
  performanceProfiling: false,
};
