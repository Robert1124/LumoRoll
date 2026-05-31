import {Composition} from 'remotion';
import {LumoRollTeaser} from './LumoRollTeaser';

export const RemotionRoot = () => (
  <Composition
    id="LumoRollTeaser"
    component={LumoRollTeaser}
    durationInFrames={180}
    fps={30}
    width={1080}
    height={1080}
  />
);

export default RemotionRoot;
