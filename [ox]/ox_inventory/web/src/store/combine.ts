
export interface CombineIngredient {
  item: string;
  count: number;
}

export interface CombineRecipe {
  id: string;
  result: string;
  count: number;
  category?: string;
  label?: string;
  duration?: number;
  ingredients: CombineIngredient[];
  layout?: (string | 0 | false)[];
}

export interface CombineCategory {
  id: string;
  label: string;
}

export interface CombineData {
  enabled: boolean;
  categories: CombineCategory[];
  recipes: CombineRecipe[];
}

export const Combine: CombineData = {
  enabled: false,
  categories: [],
  recipes: [],
};

export const setCombineData = (data?: Partial<CombineData>) => {
  if (!data) return;
  Combine.enabled = !!data.enabled;
  Combine.categories = Array.isArray(data.categories) ? data.categories : [];
  Combine.recipes = Array.isArray(data.recipes) ? data.recipes : [];
};
