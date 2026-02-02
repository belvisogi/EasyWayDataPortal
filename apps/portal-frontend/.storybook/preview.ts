import type { Preview } from '@storybook/html';
import '../src/theme.css';
import '../src/framework.css';
import '../src/style.css';

const preview: Preview = {
    parameters: {
        controls: {
            matchers: {
                color: /(background|color)$/i,
                date: /Date$/,
            },
        },
    },
};

export default preview;
