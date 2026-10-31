export type Channel = 'local' | 'ooc' | 'pm' | 'job' | 'staff' | 'system';

// Lo que llega de chat:addMessage: formato propio o el del chat de FiveM
export interface RawMessage {
  channel?: string;
  tag?: string;
  author?: string;
  detail?: string;
  id?: number;
  text?: string;
  args?: unknown[];
  color?: number[];
  template?: string;
}

export interface ChatMessage {
  key: number;
  time: number;
  channel: Channel;
  tag?: string;
  author?: string;
  detail?: string;
  id?: number;
  text: string;
  color?: string;
}

export interface Suggestion {
  name: string;
  help: string;
  params: { name: string; help?: string }[];
}

export interface Access {
  staff: boolean;
  job: string | false;
}
