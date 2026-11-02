import { ClothingConfig, ClothingSlotDefinition } from '../../typings/clothing';

export const getDefinition = (
  config: ClothingConfig | undefined,
  slotId: number
): ClothingSlotDefinition | undefined => {
  if (!config?.slots) return undefined;
  return config.slots[slotId];
};
