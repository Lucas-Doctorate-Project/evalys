# coding: utf-8

import matplotlib.gridspec

from . import core
from . import gantt
from . import lifecycle
from . import series
from .. import utils


class DetailsLayout(core.EvalysLayout):
    """
    Layout in 4 horizontal stripes.

    This layout is a support to combine various already-existing
    visualizations.
    """
    def __init__(self, *, wtitle='Detailed Figure'):
        super().__init__(wtitle=wtitle)

        gs = matplotlib.gridspec.GridSpec(nrows=4, ncols=1)

        visualizations = 'utilization', 'queue', 'lifecycle', 'gantt'
        for idx, visu in enumerate(visualizations):
            self.sps[visu] = gs[idx, :]

    def show(self):
        # enforce sharing of the x-axis across all stripes by merging every
        # axis into a single shared-x group.  matplotlib 3.6 made
        # get_shared_x_axes() return a read-only view and Axes.sharex refuses
        # axes that already share an axis (e.g. the lifecycle sub-axes), so we
        # join the underlying Grouper directly.
        axes = self.fig.get_axes()
        axes[0]._shared_axes['x'].join(*axes)

        super().show()


def plot_details(jobset, *, title='Workload overview', **kwargs):
    """
    Helper function to create a detailed overview of a workload.

    :param jobset: The jobset under study.
    :type jobset: `JobSet`

    :param title: The title of the window.
    :type title: str

    :param \**kwargs:
        The keyword arguments to be fed to the constructors of the
        visualization classes.
    """
    visualizations = {
        'gantt': gantt.GanttVisualization,
        'lifecycle': lifecycle.LifecycleVisualization,
        'queue': series.QueueSeriesVisualization,
        'utilization': series.UtilizationSeriesVisualization,
    }

    layout = DetailsLayout(wtitle=title)
    for spskey, visu_cls in visualizations.items():
        plot = layout.inject(visu_cls, spskey=spskey)
        utils.bulksetattr(plot, **kwargs)
        plot.build(jobset)
    layout.show()
