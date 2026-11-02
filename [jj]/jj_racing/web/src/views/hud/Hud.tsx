import { useHud } from "./useHud";
import { RaceHud } from "./RaceHud";
import { CreatorOverlay } from "./CreatorOverlay";

/** HUD de carrera (hud:*) y overlay del editor (creator:*): transparente y sin capturar foco */
export function Hud() {
  const { state, clock, pitVisible } = useHud();
  return (
    <>
      {state.visible && <RaceHud state={state} clock={clock} pitVisible={pitVisible} />}
      <CreatorOverlay />
    </>
  );
}
